# frozen_string_literal: true

require './spec/support/sidekiq_middleware'

class Gitlab::Seeder::ComposerPackages
  attr_reader :organization

  def initialize(organization:)
    @organization = organization
  end

  def group
    @group ||= Group.find_by(path: 'composer')

    unless @group
      @group = Group.create!(
        name: 'Composer',
        path: 'composer',
        description: FFaker::Lorem.sentence,
        organization: organization
      )

      @group.add_owner(user)
      @group.create_namespace_settings
    end

    @group
  end

  def user
    @user ||= User.first
  end

  def create_real_project!(url)
    project_path = url.split('/').last

    project_path.gsub!(".git", "")

    project = group.projects.find_by(name: project_path.titleize)

    return project if project.present?

    params = {
      import_url: url,
      namespace_id: group.id,
      name: project_path.titleize,
      description: FFaker::Lorem.sentence,
      visibility_level: Gitlab::VisibilityLevel.values.sample,
      skip_disk_validation: true
    }

    Sidekiq::Worker.skipping_transaction_check do
      project = ::Projects::CreateService.new(user, params).execute

      # Seed-Fu runs this entire fixture in a transaction, so the `after_commit`
      # hook won't run until after the fixture is loaded. That is too late
      # since the Sidekiq::Testing block has already exited. Force clearing
      # the `after_commit` queue to ensure the job is run now.
      project.send(:_run_after_commit_queue)
      project.import_state.send(:_run_after_commit_queue)

      # Expire repository cache after import to ensure
      # valid_repo? call below returns a correct answer
      project.repository.expire_all_method_caches
    end

    if project.valid? && project.valid_repo?
      print '.'
      return project
    else
      puts project.errors.full_messages
      print 'F'
      return nil
    end
  end
end

COMPOSER_PACKAGES = {
  'https://github.com/php-fig/log.git' => [
    { branch: 'master' },
    { tag: 'v1.5.2' }
  ],
  'https://github.com/ryssbowh/craft-themes.git' => [
    { tag: '1.0.2' }
  ],
  'https://github.com/php-fig/http-message.git' => [
    { tag: '1.0.1' }
  ],
  'https://github.com/doctrine/instantiator.git' => [
    { branch: '1.4.x' }
  ]
}.freeze

Gitlab::Seeder.quiet do
  flag = 'SEED_COMPOSER'

  unless ENV[flag]
    puts "Use the `#{flag}` environment variable to seed composer packages"
    next
  end

  Sidekiq::Testing.inline! do
    COMPOSER_PACKAGES.each do |path, versions|
      project = Gitlab::Seeder::ComposerPackages.new(organization: Organizations::Organization.default_organization)
      project.create_real_project!(path)

      versions.each do |version|
        params = {}

        if version[:branch]
          params[:branch] = project.repository.find_branch(version[:branch])
        elsif version[:tag]
          params[:tag] = project.repository.find_tag(version[:tag])
        end

        if params[:branch].nil? && params[:tag].nil?
          puts "version #{version.inspect} not found"
          next
        end

        Sidekiq::Worker.skipping_transaction_check do
          ::Packages::Composer::CreatePackageService
            .new(project, project.owner, params)
            .execute
        end

        puts "version #{version.inspect} created!"
      end
    end
  end
end
