require './spec/support/sidekiq'

# rubocop:disable Rails/Output

Sidekiq::Testing.inline! do
  Gitlab::Seeder.quiet do
    Gitlab::Seeder.without_gitaly_timeout do
      project_urls = %w[
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

      large_project_urls = %w[
        https://github.com/torvalds/linux.git
        https://gitlab.gnome.org/GNOME/gimp.git
        https://gitlab.gnome.org/GNOME/gnome-mud.git
        https://gitlab.com/fdroid/fdroidclient.git
        https://gitlab.com/inkscape/inkscape.git
        https://github.com/gnachman/iTerm2.git
      ]

      def create_project(url, force_latest_storage: false)
        group_path, project_path = url.split('/')[-2..-1]

        group = Group.find_by(path: group_path)

        unless group
          group = Group.new(
            name: group_path.titleize,
            path: group_path
          )
          group.description = FFaker::Lorem.sentence
          group.save!

          group.add_owner(User.first)
        end

        project_path.gsub!(".git", "")

        params = {
          import_url: url,
          namespace_id: group.id,
          name: project_path.titleize,
          description: FFaker::Lorem.sentence,
          visibility_level: Gitlab::VisibilityLevel.values.sample,
          skip_disk_validation: true
        }

        if force_latest_storage
          params[:storage_version] = Project::LATEST_STORAGE_VERSION
        end

        project = nil

        Sidekiq::Worker.skipping_transaction_check do
          project = Projects::CreateService.new(User.first, params).execute

          # Seed-Fu runs this entire fixture in a transaction, so the `after_commit`
          # hook won't run until after the fixture is loaded. That is too late
          # since the Sidekiq::Testing block has already exited. Force clearing
          # the `after_commit` queue to ensure the job is run now.
          project.send(:_run_after_commit_queue)
          project.import_state.send(:_run_after_commit_queue)
        end

        if project.valid? && project.valid_repo?
          print '.'
        else
          puts project.errors.full_messages
          print 'F'
        end
      end

      # You can specify how many projects you need during seed execution
      size = ENV['SIZE'].present? ? ENV['SIZE'].to_i : 8

      project_urls.first(size).each_with_index do |url, i|
        create_project(url, force_latest_storage: i.even?)
      end

      if ENV['LARGE_PROJECTS'].present?
        large_project_urls.each(&method(:create_project))

        if ENV['FORK'].present?
          puts "\nGenerating forks"

          project_name = ENV['FORK'] == 'true' ? 'torvalds/linux' : ENV['FORK']

          project = Project.find_by_full_path(project_name)

          User.offset(1).first(5).each do |user|
            new_project = Projects::ForkService.new(project, user).execute

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
    end
  end
end
