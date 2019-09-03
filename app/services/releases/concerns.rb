# frozen_string_literal: true

module Releases
  module Concerns
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do
      def tag_name
        params[:tag]
      end

      def ref
        params[:ref]
      end

      def name
        params[:name] || tag_name
      end

      def description
        params[:description]
      end

      def released_at
        params[:released_at]
      end

      def release
        strong_memoize(:release) do
          project.releases.find_by_tag(tag_name)
        end
      end

      def existing_tag
        strong_memoize(:existing_tag) do
          repository.find_tag(tag_name)
        end
      end

      def tag_exist?
        existing_tag.present?
      end

      def repository
        strong_memoize(:repository) do
          project.repository
        end
      end

      def milestone
        return unless params[:milestone]

        strong_memoize(:milestone) do
          MilestonesFinder.new(
            project: project,
            current_user: current_user,
            project_ids: Array(project.id),
            title: params[:milestone]
          ).execute.first
        end
      end

      def inexistent_milestone?
        params[:milestone] && !params[:milestone].empty? && !milestone
      end

      def param_for_milestone_title_provided?
        params[:milestone].present? || params[:milestone]&.empty?
      end
    end
  end
end
