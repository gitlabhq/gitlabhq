# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      module Rails
        # Checks for usage of `encrypts ..., deterministic: true`.
        #
        # Rotating the encryption key is not supported for deterministic encryption,
        # so a deterministically-encrypted column can never move to a new key without
        # a manual re-encryption of every existing value.
        # See https://guides.rubyonrails.org/active_record_encryption.html#querying-encrypted-data-deterministic-vs-non-deterministic-encryption
        # and https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/migrate_to_activerecord_encryption/#proposal
        #
        # @example
        #   # bad
        #   encrypts :token, deterministic: true
        #
        #   # good
        #   encrypts :token
        #
        class EncryptsDeterministic < RuboCop::Cop::Base
          MSG = 'Do not use deterministic encryption with `encrypts`; deterministic encryption keys ' \
            'cannot be rotated. See https://guides.rubyonrails.org/active_record_encryption.html' \
            '#querying-encrypted-data-deterministic-vs-non-deterministic-encryption'

          RESTRICT_ON_SEND = [:encrypts].freeze

          def on_send(node)
            node.arguments.each do |arg|
              next unless arg.hash_type?

              arg.pairs.each do |pair|
                next unless pair.key.sym_type? && pair.key.value == :deterministic
                next if pair.value.false_type?

                add_offense(pair)
              end
            end
          end
          alias_method :on_csend, :on_send
        end
      end
    end
  end
end
