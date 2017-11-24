require 'securerandom'

module QA
  module Scenario
    module Gitlab
      module Project
        class Create < Scenario::Template
          attr_writer :description

          def name=(name)
            @name = "#{name}-#{SecureRandom.hex(8)}"
          end

          def perform(with_repo: false)
            Scenario::Gitlab::Sandbox::Prepare.perform

            Page::Group::Show.perform do |page|
              if page.has_subgroup?(Runtime::Namespace.name)
                page.go_to_subgroup(Runtime::Namespace.name)
              else
                page.go_to_new_subgroup

                Scenario::Gitlab::Group::Create.perform do |group|
                  group.path = Runtime::Namespace.name
                end
              end

              page.go_to_new_project
            end

            Page::Project::New.perform do |page|
              page.choose_test_namespace
              page.choose_name(@name)
              page.add_description(@description)
              page.create_new_project
            end

            if with_repo
              Git::Repository.perform do |repository|
                repository.location = Page::Project::Show.act do
                  choose_repository_clone_http
                  repository_location
                end
                repository.use_default_credentials

                repository.act do
                  clone
                  configure_identity('GitLab QA', 'root@gitlab.com')
                  commit_file('test.rb', 'class Test; end', 'Add Test class')
                  commit_file('README.md', '# Test', 'Add Readme')
                  push_changes
                end
              end

              Page::Project::Show.act do
                wait_for_push
                refresh
              end
            end
          end
        end
      end
    end
  end
end
