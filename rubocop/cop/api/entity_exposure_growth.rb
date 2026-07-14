# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Prevents adding `expose` calls to high-impact REST API entities that
      # affect many endpoints. Create a new, feature-bounded entity instead.
      #
      # The cop loads an allowlist YAML file that maps each protected entity file
      # to its `usage_radius` (the number of endpoints the entity is exposed on)
      # and the permitted field names (`fields`). Any `expose` call whose first
      # argument is a symbol not in the allowlist is flagged as an offense, and the
      # message reports the entity's usage radius. When a symbol appears multiple
      # times in the allowlist (e.g. exposed with different `as:` aliases), the cop
      # flags all occurrences of that field when the source file has more `expose`
      # calls for it than the allowlist permits.
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

        IMPACT_MSG = 'Do not add `expose` calls to high-impact entities. ' \
          'This field would be exposed on ~%{usage_radius} API endpoints. ' \
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
          @allowlist_entry = nil
          @allowlist_resolved = false
        end

        def on_send(node)
          entry = allowlist_entry_for(file_path_for_node(node))
          return unless entry

          field_name = extract_field_name(node)
          return unless field_name

          @exposures_by_field[field_name] << node
        end

        alias_method :on_csend, :on_send

        def on_investigation_end
          super
          return unless @allowlist_entry

          allowed_tally = Array(@allowlist_entry['fields']).tally
          message = message_for(@allowlist_entry['usage_radius'])

          @exposures_by_field.each do |field_name, nodes|
            next if nodes.size <= (allowed_tally[field_name] || 0)

            nodes.each { |node| add_offense(node, message: message) }
          end
        end

        def external_dependency_checksum
          self.class.external_dependency_checksum
        end

        private

        def allowlist_entry_for(file_path)
          return @allowlist_entry if @allowlist_resolved

          @allowlist_resolved = true
          matching_suffix = self.class.allowlist.each_key.find { |suffix| file_path.end_with?(suffix) }
          @allowlist_entry = self.class.allowlist[matching_suffix]
        end

        def message_for(usage_radius)
          # A usage_radius of 0 means the analyzer could not detect any endpoints for
          # the entity (e.g. it is rendered via `present ..., with:` rather than a route
          # entity setting), so no reliable count exists - fall back to the base message.
          return MSG unless usage_radius&.positive?

          format(IMPACT_MSG, usage_radius: usage_radius)
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
