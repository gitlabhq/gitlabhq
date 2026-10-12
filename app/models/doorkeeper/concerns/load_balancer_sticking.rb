# frozen_string_literal: true

module Doorkeeper # rubocop:disable Gitlab/BoundedContexts -- Override from a gem
  module Concerns
    # Clients use a new OAuth secret within milliseconds, often before every replica has
    # the row. Record the primary's write location for each secret on create and honour
    # it on lookup, so the next request reads from a caught-up replica or the primary.
    #
    # Including models define `.sticking_namespace` and `#plaintext_secrets_to_stick`.
    #
    # Each side has its own feature flag so they can roll out one after the other:
    # `stick_new_oauth_tokens_to_primary` records the location on create, which the
    # explicit stick in `Gitlab::Auth::AuthFinders#find_oauth_access_token` already honours
    # for API requests; `oauth_lookups_use_load_balancer_sticking` makes every other lookup
    # honour it too.
    module LoadBalancerSticking
      extend ActiveSupport::Concern

      included do
        after_commit :stick_to_database_load_balancer, on: :create
      end

      class_methods do
        # Doorkeeper routes `by_token`, `by_refresh_token` and the grant's `by_token` through here.
        def find_by_plaintext_token(attr, token)
          find_caught_up_replica_for(token)

          super
        end

        private

        def find_caught_up_replica_for(plaintext)
          plaintext = plaintext.to_s

          # Doorkeeper issues 32-byte hex secrets; skip PATs, deploy tokens and Git HTTP passwords.
          return unless plaintext.match?(/\A\h{64}\z/)
          return unless Feature.enabled?(:oauth_lookups_use_load_balancer_sticking, Feature.current_request)

          sticking.find_caught_up_replica(sticking_namespace, plaintext, hash_id: true)
        rescue StandardError => e
          # Git over HTTP, LFS and registry logins reach this lookup before the other
          # credential checks, so a Redis outage must not fail them. Fall through to a
          # normal read, which only risks the replica-lag miss this concern exists to prevent.
          Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, model: name, namespace: sticking_namespace)
        end
      end

      private

      def stick_to_database_load_balancer
        return unless Feature.enabled?(:stick_new_oauth_tokens_to_primary, Feature.current_request)

        # One write-location query on the primary covers every secret of the record.
        self.class.sticking.bulk_stick(self.class.sticking_namespace, plaintext_secrets_to_stick, hash_id: true)
      rescue StandardError => e
        # The row is committed and the secret must still reach the client; an unstuck
        # secret only risks the replica-lag miss this concern exists to prevent.
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, model: self.class.name, record_id: id)
      end
    end
  end
end
