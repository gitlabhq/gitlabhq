# frozen_string_literal: true

module Gitlab
  module ExternalAuthorization
    class Logger < ::Gitlab::Logger
      def self.log_access(access, project_path)
        status = access.has_access? ? "GRANTED" : "DENIED"
        message = ["#{status} #{access.user.email} access to '#{access.label}'"]

        message << "(#{project_path})" if project_path.present?
        message << "- #{access.load_type} #{access.loaded_at}" if access.load_type == :cache

        info(message.join(' '))
      end

      def self.file_name_noext
        'external-policy-access-control'
      end
    end
  end
end
