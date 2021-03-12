# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    module Wiki
      class GroupPage < Base
        attribute :title
        attribute :content
        attribute :slug

        attribute :group do
          Group.fabricate_via_api! do |group|
            group.path = "group-with-wiki-#{SecureRandom.hex(8)}"
          end
        end

        def initialize
          @title = 'Home'
          @content = 'This wiki page is created via API'
        end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          "#{group.web_url}/-/wikis/#{slug}"
        end

        def api_get_path
          "/groups/#{group.id}/wikis/#{slug}"
        end

        def api_post_path
          "/groups/#{group.id}/wikis"
        end

        def api_post_body
          {
            id: group.id,
            content: content,
            title: title
          }
        end
      end
    end
  end
end
