# frozen_string_literal: true

module QA
  module Resource
    module Repository
      class WikiPush < Repository::Push
        attribute :wiki do
          # We are using the project based wiki as a standard.
          Wiki::ProjectPage.fabricate_via_api! do |resource|
            resource.title = 'Home'
            resource.content = '# My First Wiki Content'
          end
        end

        def initialize
          @file_name = 'Home.md'
          @file_content = 'This line was created using git push'
          @commit_message = 'Updating using git push'
          @new_branch = false
        end

        def repository_http_uri
          @repository_http_uri ||= wiki.repository_http_location.uri
        end

        def repository_ssh_uri
          @repository_ssh_uri ||= wiki.repository_ssh_location.uri
        end

        def web_url
          # TODO
          # workaround
          # i.e. This replaces the last occurence of the string (case sensitive)
          # and attaches everything before to the new substring
          wiki_title = ERB::Util.url_encode(@file_name.gsub('.md', ''))
          repository_http_uri.to_s.gsub(/(.*)\b\.wiki\.git\b/i, "\\1/-/wikis/#{wiki_title}")
        end
      end
    end
  end
end
