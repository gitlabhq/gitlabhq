# frozen_string_literal: true

require './spec/support/sidekiq_middleware'
require './lib/gitlab/faker/internet'

class Gitlab::Seeder::Users
  include ActionView::Helpers::NumberHelper

  RANDOM_USERS_COUNT = 20
  MASS_NAMESPACES_COUNT = ENV['CI'] ? 1 : 100
  MASS_USERS_COUNT = ENV['CI'] ? 10 : 1_000_000
  attr_reader :organization

  def initialize(organization: )
    @organization = organization
  end

  def seed!
    Sidekiq::Testing.inline! do
      create_mass_users!
      create_mass_namespaces!
      create_random_users!
    end
  end

  private

  def create_mass_users!
    encrypted_password = Devise::Encryptor.digest(User, random_password)

    Gitlab::Seeder.with_mass_insert(MASS_USERS_COUNT, User) do
      ActiveRecord::Base.connection.execute <<~SQL
        INSERT INTO users (username, name, email, state, confirmed_at, projects_limit, encrypted_password)
        SELECT
          '#{Gitlab::Seeder::MASS_INSERT_USER_START}' || seq,
          'Seed user ' || seq,
          'seed_user' || seq || '@example.com',
          'active',
          to_timestamp(seq),
          #{MASS_USERS_COUNT},
          '#{encrypted_password}'
        FROM generate_series(1, #{MASS_USERS_COUNT}) AS seq
        ON CONFLICT DO NOTHING;
      SQL
    end

    relation = User.where(admin: false)
    Gitlab::Seeder.with_mass_insert(relation.count, 'user namespaces') do
      ActiveRecord::Base.connection.execute <<~SQL
        INSERT INTO namespaces (name, path, owner_id, type, organization_id)
        SELECT
          username,
          username,
          id,
          'User',
          #{organization.id}
        FROM users WHERE NOT admin
        ON CONFLICT DO NOTHING;
      SQL
    end

    Gitlab::Seeder.with_mass_insert(relation.count, "User namespaces routes") do
      ActiveRecord::Base.connection.execute <<~SQL
        INSERT INTO routes (namespace_id, source_id, source_type, path, name)
        SELECT id as namespace_id, id as source_id, 'Namespace', path, name
          FROM namespaces WHERE type IS NULL OR type = 'User'
          ON CONFLICT DO NOTHING;
      SQL
    end

    puts '==========================================================='
    puts "INFO: Password for newly created users is: #{random_password}"
    puts '==========================================================='
  end

  def create_random_users!
    RANDOM_USERS_COUNT.times do |i|
      begin
        User.create!(
          username: Gitlab::Faker::Internet.unique_username,
          name: FFaker::Name.name,
          email: FFaker::Internet.email,
          confirmed_at: DateTime.now,
          password: random_password
        ) do |user|
          user.assign_personal_namespace(organization)
        end

        print '.'
      rescue ActiveRecord::RecordInvalid
        print 'F'
      end
    end
  end

  def create_mass_namespaces!
    Gitlab::Seeder.with_mass_insert(MASS_NAMESPACES_COUNT, "root namespaces and subgroups 9 levels deep") do
      ActiveRecord::Base.connection.execute <<~SQL
        INSERT INTO namespaces (name, path, type, organization_id)
        SELECT
          'mass insert group level 0 - ' || seq,
          '#{Gitlab::Seeder::MASS_INSERT_GROUP_START}_0_' || seq,
          'Group',
          #{organization.id}
        FROM generate_series(1, #{MASS_NAMESPACES_COUNT}) AS seq
        ON CONFLICT DO NOTHING;
      SQL

      (1..9).each do |idx|
        count = Namespace.where("path LIKE '#{Gitlab::Seeder::MASS_INSERT_PREFIX}%'").where(type: 'Group').count * 2
        Gitlab::Seeder.log_message("Creating subgroups at level #{idx}: #{count}")
        ActiveRecord::Base.connection.execute <<~SQL
          INSERT INTO namespaces (name, path, type, parent_id, organization_id)
          SELECT
            'mass insert group level #{idx} - ' || seq,
            '#{Gitlab::Seeder::MASS_INSERT_GROUP_START}_#{idx}_' || seq,
            'Group',
            namespaces.id,
            namespaces.organization_id
          FROM namespaces
          CROSS JOIN generate_series(1, 2) AS seq
          WHERE namespaces.type='Group' AND namespaces.path like '#{Gitlab::Seeder::MASS_INSERT_GROUP_START}_#{idx-1}_%'
          ON CONFLICT DO NOTHING;
        SQL
      end

      Gitlab::Seeder.log_message("creating routes.")
      ActiveRecord::Base.connection.execute <<~SQL
        WITH RECURSIVE cte(source_id, namespace_id, parent_id, path, height) AS (
          (
            SELECT ARRAY[batch.id], batch.id, batch.parent_id, batch.path, 1
            FROM
              "namespaces" as batch
            WHERE
              "batch"."type" = 'Group' AND "batch"."parent_id" is null
          )
        UNION
          (
            SELECT array_append(cte.source_id, n.id), n.id, n.parent_id, cte.path || '/' || n.path, cte.height+1
            FROM
              "namespaces" as n,
              "cte"
            WHERE
              "n"."type" = 'Group'
              AND "n"."parent_id" = "cte"."namespace_id"
          )
        )
        INSERT INTO routes (namespace_id, source_id, source_type, path, name)
          SELECT cte.namespace_id as namespace_id, cte.namespace_id as source_id, 'Namespace', cte.path, cte.path FROM cte
          ON CONFLICT DO NOTHING;
      SQL

      Gitlab::Seeder.log_message("filling traversal ids.")
      ActiveRecord::Base.connection.execute <<~SQL
        WITH RECURSIVE cte(source_id, namespace_id, parent_id) AS (
          (
            SELECT ARRAY[batch.id], batch.id, batch.parent_id
            FROM
              "namespaces" as batch
            WHERE
              "batch"."type" = 'Group' AND "batch"."parent_id" is null
          )
        UNION
          (
            SELECT array_append(cte.source_id, n.id), n.id, n.parent_id
            FROM
              "namespaces" as n,
              "cte"
            WHERE
              "n"."type" = 'Group'
              AND "n"."parent_id" = "cte"."namespace_id"
          )
        )
        UPDATE namespaces
        SET traversal_ids = computed.source_id FROM (SELECT namespace_id, source_id FROM cte) AS computed
        where computed.namespace_id = namespaces.id AND namespaces.path LIKE '#{Gitlab::Seeder::MASS_INSERT_PREFIX}%'
      SQL

      Gitlab::Seeder.log_message("creating namespace settings.")
      ActiveRecord::Base.connection.execute <<~SQL
        INSERT INTO namespace_settings(namespace_id, created_at, updated_at)
        SELECT id, now(), now() FROM namespaces
        ON CONFLICT DO NOTHING;
      SQL
    end
  end


  def random_password
    @random_password ||= SecureRandom.hex.slice(0,16)
  end
end

Gitlab::Seeder.quiet do
  users = Gitlab::Seeder::Users.new(organization: Organizations::Organization.default_organization)
  users.seed!
end
