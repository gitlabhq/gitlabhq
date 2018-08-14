module QA
  module Factory
    module Repository
      class WikiPush < Factory::Repository::Push
        dependency Factory::Resource::Wiki, as: :wiki do |wiki|
          wiki.title = 'Home'
          wiki.content = '# My First Wiki Content'
          wiki.message = 'Update home'
        end

        def initialize
          @file_name = 'Home.md'
          @file_content = '# Welcome to My Wiki'
          @commit_message = 'Updating Home Page'
          @branch_name = 'master'
          @new_branch = false
        end

        def repository_uri
          @repository_uri ||= begin
            wiki.visit!
            Page::Project::Wiki::Show.act do
              go_to_clone_repository
              choose_repository_clone_http
              repository_location.uri
            end
          end
        end
      end
    end
  end
end
