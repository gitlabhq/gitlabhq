# frozen_string_literal: true

module QA
  module Resource
    class GroupLabel < LabelBase
      attribute :group do
        Group.fabricate! do |resource|
          resource.name = 'group-with-label'
        end
      end

      def fabricate!
        raise NotImplementedError
      end

      def api_post_path
        "/groups/#{CGI.escape(group.full_path)}/labels"
      end

      def api_get_path
        "/groups/#{CGI.escape(group.full_path)}/labels/#{id}"
      end
    end
  end
end
