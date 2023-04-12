# frozen_string_literal: true

module Gitlab
  module Git
    class BlameMode
      def initialize(project, params)
        @project = project
        @params = params
      end

      def streaming_supported?
        Feature.enabled?(:blame_page_streaming, project)
      end

      def streaming?
        return false unless streaming_supported?

        Gitlab::Utils.to_boolean(params[:streaming], default: false)
      end

      def pagination?
        return false if streaming?
        return false if Gitlab::Utils.to_boolean(params[:no_pagination], default: false)

        Feature.enabled?(:blame_page_pagination, project)
      end

      def full?
        !streaming? && !pagination?
      end

      private

      attr_reader :project, :params
    end
  end
end
