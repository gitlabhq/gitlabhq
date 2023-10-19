# frozen_string_literal: true

module QA
  module Resource
    module Wiki
      class ProjectPage < Base
        attribute :title
        attribute :content
        attribute :slug
        attribute :format
        attribute :web_url do
          "#{project.web_url}/-/wikis/#{slug}"
        end

        attribute :project do
          Project.fabricate_via_api! do |project|
            project.name = 'wiki_testing'
            project.description = 'project for testing wikis'
          end
        end

        attribute :repository_http_location do
          switching_to_wiki_url project.repository_http_location.git_uri
        end

        attribute :repository_ssh_location do
          switching_to_wiki_url project.repository_ssh_location.git_uri
        end

        def initialize
          @title = 'Home'
          @content = 'This wiki page is created by the API'
        end

        def resource_web_url(_)
          web_url
        end

        def api_get_path
          "/projects/#{project.id}/wikis/#{slug}"
        end

        def api_post_path
          "/projects/#{project.id}/wikis"
        end

        def api_post_body
          {
            id: project.id,
            content: content,
            title: title
          }
        end

        private

        def switching_to_wiki_url(url)
          # TODO
          # workaround
          # i.e. This replaces the last occurence of the string (case sensitive)
          # and attaches everything before to the new substring
          Git::Location.new(url.to_s.gsub(/(.*)\bgit\b/i, '\1wiki.git'))
        end
      end
    end
  end
end
