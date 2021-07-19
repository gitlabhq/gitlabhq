# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Scanner
          ANALYZER_ORDER = {
            "bundler_audit" => 1,
            "retire.js" =>  2,
            "gemnasium" => 3,
            "gemnasium-maven" => 3,
            "gemnasium-python" => 3,
            "bandit" => 1,
            "semgrep" =>  2
          }.freeze

          attr_accessor :external_id, :name, :vendor, :version

          alias_method :key, :external_id

          def initialize(external_id:, name:, vendor:, version:)
            @external_id = external_id
            @name = name
            @vendor = vendor
            @version = version
          end

          def to_hash
            {
              external_id: external_id.to_s,
              name: name.to_s,
              vendor: vendor.presence
            }.compact
          end

          def ==(other)
            other.external_id == external_id
          end

          def <=>(other)
            sort_keys.compact <=> other.sort_keys.compact
          end

          protected

          def sort_keys
            @sort_keys ||= [order, external_id, name, vendor]
          end

          private

          def order
            ANALYZER_ORDER.fetch(external_id, Float::INFINITY)
          end
        end
      end
    end
  end
end
