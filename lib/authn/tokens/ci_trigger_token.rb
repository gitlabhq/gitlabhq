# frozen_string_literal:true

module Authn
  module Tokens
    class CiTriggerToken
      def self.prefix?(plaintext)
        prefixes = [::Ci::Trigger::TRIGGER_TOKEN_PREFIX, ::Ci::Trigger.prefix_for_trigger_token].uniq

        plaintext.start_with?(*prefixes)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Ci::Trigger.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Trigger
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        unless Feature.enabled?(:token_api_expire_pipeline_triggers, revocable.project)
          raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type'
        end

        ::Ci::PipelineTriggers::ExpireService.new(user: current_user, trigger: revocable).execute
      end
    end
  end
end
