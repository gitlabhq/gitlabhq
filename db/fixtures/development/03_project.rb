require './spec/support/sidekiq_middleware'

class Gitlab::Seeder::Projects
  include ActionView::Helpers::NumberHelper

  PROJECT_URLS = %w[
    https://gitlab.com/gitlab-com/support/toolbox/gitlab-smoke-tests.git
    https://gitlab.com/gitlab-org/gitlab-test.git
    https://gitlab.com/gitlab-org/gitlab-shell.git
    https://gitlab.com/gnuwget/wget2.git
    https://gitlab.com/Commit451/LabCoat.git
    https://github.com/jashkenas/underscore.git
    https://github.com/flightjs/flight.git
    https://github.com/twitter/typeahead.js.git
    https://github.com/h5bp/html5-boilerplate.git
    https://github.com/google/material-design-lite.git
    https://github.com/jlevy/the-art-of-command-line.git
    https://github.com/FreeCodeCamp/freecodecamp.git
    https://github.com/google/deepdream.git
    https://github.com/jtleek/datasharing.git
    https://github.com/WebAssembly/design.git
    https://github.com/airbnb/javascript.git
    https://github.com/tessalt/echo-chamber-js.git
    https://github.com/atom/atom.git
    https://github.com/mattermost/mattermost-server.git
    https://github.com/purifycss/purifycss.git
    https://github.com/facebook/nuclide.git
    https://github.com/wbkd/awesome-d3.git
    https://github.com/kilimchoi/engineering-blogs.git
    https://github.com/gilbarbara/logos.git
    https://github.com/reduxjs/redux.git
    https://github.com/awslabs/s2n.git
    https://github.com/arkency/reactjs_koans.git
    https://github.com/twbs/bootstrap.git
    https://github.com/chjj/ttystudio.git
    https://github.com/MostlyAdequate/mostly-adequate-guide.git
    https://github.com/octocat/Spoon-Knife.git
    https://github.com/opencontainers/runc.git
    https://github.com/googlesamples/android-topeka.git
  ]
  LARGE_PROJECT_URLS = %w[
    https://github.com/torvalds/linux.git
    https://gitlab.gnome.org/GNOME/gimp.git
    https://gitlab.gnome.org/GNOME/gnome-mud.git
    https://gitlab.com/fdroid/fdroidclient.git
    https://gitlab.com/inkscape/inkscape.git
    https://github.com/gnachman/iTerm2.git
  ]
  # Consider altering MASS_USERS_COUNT for less
  # users with projects.
  MASS_PROJECTS_COUNT_PER_USER = {
    private: 3, # 3m projects +
    internal: 1, # 1m projects +
    public: 1 # 1m projects = 5m total
  }

  BATCH_SIZE = 100_000

  attr_reader :organization

  def initialize(organization:)
    @organization = organization
   end

  def seed!
    Sidekiq::Testing.inline! do
      create_real_projects!
      create_large_projects!
    end
  end

  def self.insert_project_namespaces_sql(type:, range:)
    <<~SQL
          INSERT INTO namespaces (name, path, organization_id, parent_id, owner_id, type, visibility_level, created_at, updated_at)
          SELECT
            'Seed project ' || seq || ' ' || ('{#{Gitlab::Seeder::Projects.visibility_per_user}}'::text[])[seq] AS project_name,
            '#{Gitlab::Seeder::MASS_INSERT_PROJECT_START}' || ('{#{Gitlab::Seeder::Projects.visibility_per_user}}'::text[])[seq] || '_' || seq AS namespace_path,
            n.organization_id as organization_id,
            n.id AS parent_id,
            n.owner_id AS owner_id,
            'Project' AS type,
            ('{#{Gitlab::Seeder::Projects.visibility_level_per_user}}'::int[])[seq] AS visibility_level,
            NOW() AS created_at,
            NOW() AS updated_at
          FROM namespaces n
            CROSS JOIN generate_series(1, #{Gitlab::Seeder::Projects.projects_per_user_count}) AS seq
            WHERE type='#{type}' AND path LIKE '#{Gitlab::Seeder::MASS_INSERT_PREFIX}%'
            AND n.id BETWEEN #{range.first} AND #{range.last}
          ON CONFLICT DO NOTHING;
    SQL
  end

  def self.insert_projects_sql(type:, range:)
    <<~SQL
          INSERT INTO projects (name, path, creator_id, organization_id, namespace_id, project_namespace_id, visibility_level, created_at, updated_at)
          SELECT
            n.name AS project_name,
            n.path AS project_path,
            n.owner_id AS creator_id,
            n.organization_id AS organization_id,
            n.parent_id AS namespace_id,
            n.id AS project_namespace_id,
            n.visibility_level AS visibility_level,
            NOW() AS created_at,
            NOW() AS updated_at
          FROM namespaces n
            WHERE type = 'Project' AND n.parent_id IN (
              SELECT id FROM namespaces n1 WHERE type='#{type}'
              AND path LIKE '#{Gitlab::Seeder::MASS_INSERT_PREFIX}%' AND n1.id BETWEEN #{range.first} AND #{range.last}
            )
          ON CONFLICT DO NOTHING;
    SQL
  end

  def self.create_real_project!(organization:, url: nil, force_latest_storage: false, project_path: nil, group_path: nil)
    if url
      group_path, project_path = url.split('/')[-2..-1]
    end

    group = Group.find_by(path: group_path)

    unless group
      group = Group.new(
        name: group_path.titleize,
        path: group_path,
        organization: organization
      )
      group.description = FFaker::Lorem.sentence
      group.save!

      group.add_owner(User.first)
      group.create_namespace_settings
    end

    project_path.gsub!(".git", "")
    project = Project.find_by_name(project_path.titleize)

    if project
      puts "Project #{project.full_path} already exists, skipping"
      return
    end

    params = {
      import_url: url,
      organization_id: organization.id,
      namespace_id: group.id,
      name: project_path.titleize,
      description: FFaker::Lorem.sentence,
      visibility_level: Gitlab::VisibilityLevel.values.sample,
      skip_disk_validation: true
    }

    if force_latest_storage
      params[:storage_version] = Project::LATEST_STORAGE_VERSION
    end

    Gitlab::ExclusiveLease.skipping_transaction_check do
      Sidekiq::Worker.skipping_transaction_check do
        project = ::Projects::CreateService.new(User.first, params).execute

        # Seed-Fu runs this entire fixture in a transaction, so the `after_commit`
        # hook won't run until after the fixture is loaded. That is too late
        # since the Sidekiq::Testing block has already exited. Force clearing
        # the `after_commit` queue to ensure the job is run now.
        project.send(:_run_after_commit_queue)
        project.import_state&.send(:_run_after_commit_queue)

        # Expire repository cache after import to ensure
        # valid_repo? call below returns a correct answer
        project.repository.expire_all_method_caches
      end
    end

    if project.valid? && project.valid_repo?
      print '.'
    else
      puts project.errors.full_messages
      print 'F'
    end
  end

  private

  def create_real_projects!
    # You can specify how many projects you need during seed execution
    size = ENV['SIZE'].present? ? ENV['SIZE'].to_i : 8

    PROJECT_URLS.first(size).each_with_index do |url, i|
      self.class.create_real_project!(url: url, force_latest_storage: i.even?, organization: organization)
    end
  end

  def create_large_projects!
    return unless ENV['LARGE_PROJECTS'].present?

    LARGE_PROJECT_URLS.each do |url|
      self.class.create_real_project!(url: url, organization: organization)
    end

    if ENV['FORK'].present?
      puts "\nGenerating forks"

      project_name = ENV['FORK'] == 'true' ? 'torvalds/linux' : ENV['FORK']

      project = Project.find_by_full_path(project_name)

      User.offset(1).first(5).each do |user|
        response = ::Projects::ForkService.new(project, user).execute

        if response.error?
          print 'F'
          puts response.errors
          next
        end

        new_project = response[:project]

        if new_project.valid? && (new_project.valid_repo? || new_project.import_state.scheduled?)
          print '.'
        else
          new_project.errors.full_messages.each do |error|
            puts "#{new_project.full_path}: #{error}"
          end
          print 'F'
        end
      end
    end
  end

  def self.projects_per_user_count
    MASS_PROJECTS_COUNT_PER_USER.values.sum
  end

  def self.visibility_per_user_array
    ['private'] * MASS_PROJECTS_COUNT_PER_USER.fetch(:private) +
      ['internal'] * MASS_PROJECTS_COUNT_PER_USER.fetch(:internal) +
      ['public'] * MASS_PROJECTS_COUNT_PER_USER.fetch(:public)
  end

  def self.visibility_level_per_user_map
    visibility_per_user_array.map { |visibility| Gitlab::VisibilityLevel.level_value(visibility) }
  end

  def self.visibility_per_user
    visibility_per_user_array.join(',')
  end

  def self.visibility_level_per_user
    visibility_level_per_user_map.join(',')
  end
end

Gitlab::Seeder.quiet do
  projects = Gitlab::Seeder::Projects.new(organization: Organizations::Organization.default_organization)
  projects.seed!
end
