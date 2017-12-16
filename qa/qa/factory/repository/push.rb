require "pry-byebug"

module QA
  module Factory
    module Repository
      class Push < Factory::Base
        PAGE_REGEX_CHECK =
          %r{\/#{Runtime::Namespace.sandbox_name}\/qa-test[^\/]+\/{1}[^\/]+\z}.freeze

        attr_writer :file_name,
                    :file_content,
                    :commit_message,
                    :branch_name

        def initialize
          @file_name = 'file.txt'
          @file_content = '# This is test project'
          @commit_message = "Add #{@file_name}"
          @branch_name = 'master'
        end

        def fabricate!
          Git::Repository.perform do |repository|
            repository.location = Page::Project::Show.act do
              unless PAGE_REGEX_CHECK.match(current_path)
                raise "To perform this scenario the current page should be project show."
              end

              choose_repository_clone_http
              repository_location
            end

            repository.use_default_credentials
            repository.clone
            repository.configure_identity('GitLab QA', 'root@gitlab.com')

            repository.add_file(@file_name, @file_content)
            repository.commit(@commit_message)
            repository.push_changes(@branch_name)
          end
        end
      end
    end
  end
end
