# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Prevents adding `expose` calls to high-impact REST API entities that
      # affect many endpoints. Create a new, feature-bounded entity instead.
      #
      # The cop loads an allowlist YAML file that records the permitted field
      # names per protected entity file. Any `expose` call whose first argument
      # is a symbol not in the allowlist is flagged as an offense. When a symbol
      # appears multiple times in the allowlist (e.g. exposed with different
      # `as:` aliases), the cop flags all occurrences of that field when the
      # source file has more `expose` calls for it than the allowlist permits.
      #
      # @example
      #
      #   # bad - adding expose to a high-impact entity like UserBasic
      #   module API
      #     module Entities
      #       class UserBasic < UserSafe
      #         expose :new_field, documentation: { type: 'String' }
      #       end
      #     end
      #   end
      #
      #   # good - create a domain-scoped entity used only by the endpoints that need it
      #   module API
      #     module Entities
      #       class JobOwner < UserBasic
      #         expose :new_field, documentation: { type: 'String' }
      #       end
      #     end
      #   end
      class EntityExposureGrowth < RuboCop::Cop::Base
        include CodeReuseHelpers

        MSG = 'Do not add `expose` calls to high-impact entities. ' \
          'Create a new, feature-bounded entity instead. ' \
          'See https://docs.gitlab.com/development/api_styleguide/#high-impact-entities-and-feature-bounded-entities'

        RESTRICT_ON_SEND = %i[expose].freeze

        class << self
          def external_dependency_checksum
            @external_dependency_checksum ||= Digest::SHA256.file(allowlist_file_path).hexdigest
          end

          def allowlist
            @allowlist ||= YAML.load_file(allowlist_file_path)
          end

          def allowlist_file_path
            File.expand_path("config/api_entity_exposure_baseline.yml", __dir__)
          end
        end

        def on_new_investigation
          super
          @exposures_by_field = Hash.new { |h, k| h[k] = [] }
          @allowlist_tally = nil
        end

        def on_send(node)
          allowed_tally = allowlist_tally_for(file_path_for_node(node))
          return unless allowed_tally

          field_name = extract_field_name(node)
          return unless field_name

          @exposures_by_field[field_name] << node
        end

        alias_method :on_csend, :on_send

        def on_investigation_end
          super
          return unless @allowlist_tally

          @exposures_by_field.each do |field_name, nodes|
            next if nodes.size <= (@allowlist_tally[field_name] || 0)

            nodes.each { |node| add_offense(node) }
          end
        end

        def external_dependency_checksum
          self.class.external_dependency_checksum
        end

        private

        def allowlist_tally_for(file_path)
          @allowlist_tally ||= begin
            matching_suffix = self.class.allowlist.each_key.find { |suffix| file_path.end_with?(suffix) }

            self.class.allowlist[matching_suffix]&.tally
          end
        end

        def extract_field_name(node)
          first_arg = node.first_argument
          return unless first_arg&.sym_type?

          first_arg.value.to_s
        end
      end
    end
  end
end
