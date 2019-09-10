# frozen_string_literal: true

module QA
  module Resource
    class ProjectMember < Base
      attr_accessor :user, :project, :access_level
      attr_reader :level

      def initialize
        @level = {
          guest: 10,
          reporter: 20,
          developer: 30,
          maintainer: 40,
          owner: 50
        }
      end

      def api_get_path
        "/projects/#{project.api_resource[:id]}/members/#{user.api_resource[:id]}"
      end

      def api_post_path
        "/projects/#{project.api_resource[:id]}/members"
      end

      def api_post_body
        {
          user_id: user.api_resource[:id],
          access_level: access_level
        }
      end
    end
  end
end
