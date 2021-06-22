# frozen_string_literal: true

module Gitlab
  module Checks
    class ContainerMoved < PostPushMessage
      REDIRECT_NAMESPACE = "redirect_namespace"

      def initialize(repository, user, protocol, redirected_path)
        @redirected_path = redirected_path

        super(repository, user, protocol)
      end

      def message
        <<~MESSAGE
        #{container.class.model_name.human} '#{redirected_path}' was moved to '#{container.full_path}'.

        Please update your Git remote:

          git remote set-url origin #{url_to_repo}
        MESSAGE
      end

      private

      attr_reader :redirected_path

      def self.message_key(user, repository)
        "#{REDIRECT_NAMESPACE}:#{user.id}:#{repository.gl_repository}"
      end

      # TODO: Remove in the next release
      # https://gitlab.com/gitlab-org/gitlab/-/issues/292030
      def self.legacy_message_key(user, repository)
        return unless repository.project

        "#{REDIRECT_NAMESPACE}:#{user.id}:#{repository.project.id}"
      end
    end
  end
end
