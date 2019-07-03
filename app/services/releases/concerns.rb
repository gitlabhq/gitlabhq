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
    end
  end
end
