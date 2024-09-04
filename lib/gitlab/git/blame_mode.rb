# frozen_string_literal: true

module Gitlab
  module Git
    class BlameMode
      def initialize(project, params)
        @project = project
        @params = params
      end

      def streaming?
        Gitlab::Utils.to_boolean(params[:streaming], default: false)
      end

      def pagination?
        return false if streaming?
        return false if Gitlab::Utils.to_boolean(params[:no_pagination], default: false)

        true
      end

      def full?
        !streaming? && !pagination?
      end

      private

      attr_reader :project, :params
    end
  end
end
