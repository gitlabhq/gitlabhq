require './spec/support/sidekiq'

class Gitlab::Seeder::Projects
  include ActionView::Helpers::NumberHelper

  PROJECT_URLS = [
    'https://gitlab.com/gitlab-org/gitlab-test.git',
    'https://gitlab.com/gitlab-org/gitlab-ce.git',
    'https://gitlab.com/gitlab-org/gitlab-ci.git',
    'https://gitlab.com/gitlab-org/gitlab-shell.git',
    'https://github.com/documentcloud/underscore.git',
    'https://github.com/twitter/flight.git',
    'https://github.com/twitter/typeahead.js.git',
    'https://github.com/h5bp/html5-boilerplate.git',
    'https://github.com/google/material-design-lite.git',
    'https://github.com/jlevy/the-art-of-command-line.git',
    'https://github.com/FreeCodeCamp/freecodecamp.git',
    'https://github.com/google/deepdream.git',
    'https://github.com/jtleek/datasharing.git',
    'https://github.com/WebAssembly/design.git',
    'https://github.com/airbnb/javascript.git',
    'https://github.com/tessalt/echo-chamber-js.git',
    'https://github.com/atom/atom.git',
    'https://github.com/mattermost/platform.git',
    'https://github.com/purifycss/purifycss.git',
    'https://github.com/facebook/nuclide.git',
    'https://github.com/wbkd/awesome-d3.git',
    'https://github.com/kilimchoi/engineering-blogs.git',
    'https://github.com/gilbarbara/logos.git',
    'https://github.com/gaearon/redux.git',
    'https://github.com/awslabs/s2n.git',
    'https://github.com/arkency/reactjs_koans.git',
    'https://github.com/twbs/bootstrap.git',
    'https://github.com/chjj/ttystudio.git',
    'https://github.com/DrBoolean/mostly-adequate-guide.git',
    'https://github.com/octocat/Spoon-Knife.git',
    'https://github.com/opencontainers/runc.git',
    'https://github.com/googlesamples/android-topeka.git'
  ]
  MASS_PROJECTS_COUNT = {
    private: 2_000_000,
    internal: 30_000,
    public: 265_000
  }

  attr_reader :opts

  def initialize(opts = {})
    @opts = opts
  end

  def seed!
    Sidekiq::Testing.inline! do
      create_real_projects!(opts[:count])
      create_mass_projects!
    end
  end

  private

  def create_real_projects!(count)
    PROJECT_URLS.first(count).each_with_index do |url, i|
      group_path, project_path = url.split('/')[-2..-1]

      group = Group.find_by(path: group_path)

      unless group
        group = Group.new(
          name: group_path.titleize,
          path: group_path
        )
        group.description = FFaker::Lorem.sentence
        group.save

        group.add_owner(User.first)
      end

      project_path.gsub!(".git", "")

      params = {
        import_url: url,
        namespace_id: group.id,
        name: project_path.titleize,
        description: FFaker::Lorem.sentence,
        visibility_level: Gitlab::VisibilityLevel.values.sample
      }

      project = ::Projects::CreateService.new(User.first, params).execute
      # Seed-Fu runs this entire fixture in a transaction, so the `after_commit`
      # hook won't run until after the fixture is loaded. That is too late
      # since the Sidekiq::Testing block has already exited. Force clearing
      # the `after_commit` queue to ensure the job is run now.
      project.send(:_run_after_commit_queue)

      if project.valid? && project.valid_repo?
        print '.'
      else
        puts project.errors.full_messages
        print 'F'
      end
    end
  end

  def create_mass_projects!
    # Disable database insertion logs so speed isn't limited by ability to print to console
    old_logger = ActiveRecord::Base.logger
    ActiveRecord::Base.logger = nil

    create_mass_projects_by_visility!(:private)
    create_mass_projects_by_visility!(:internal)
    create_mass_projects_by_visility!(:public)

    # Reset logging
    ActiveRecord::Base.logger = old_logger
  end

  def create_mass_projects_by_visility!(visibility)
    users = User.limit(100)
    groups = Group.limit(100)
    namespaces = users + groups
    Project.insert_using_generate_series(1, MASS_PROJECTS_COUNT[visibility], debug: true) do |sql|
      project_name = raw("'seed_#{visibility}_project_' || seq")
      namespace = namespaces.take
      sql.name = project_name
      sql.path = project_name
      sql.creator_id = namespace.is_a?(Group) ? namespace.owner_id : users.take.id
      sql.namespace_id = namespace.is_a?(Group) ? namespace.id : namespace.namespace_id
      sql.visibility_level = Gitlab::VisibilityLevel.level_value(visibility.to_s)
    end
    puts "#{number_with_delimiter(MASS_PROJECTS_COUNT[visibility])} projects created!"
  end
end

Gitlab::Seeder.quiet do
  count = ENV['SIZE'].present? ? ENV['SIZE'].to_i : 8
  projects = Gitlab::Seeder::Projects.new(count: count)
  projects.seed!
end
