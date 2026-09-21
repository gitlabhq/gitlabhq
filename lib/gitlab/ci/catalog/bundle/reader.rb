# frozen_string_literal: true

module Gitlab
  module Ci
    module Catalog
      module Bundle
        class Reader
          include Gitlab::Utils::StrongMemoize

          def initialize(server_fqdn:, full_path:, semver:, component_name:)
            @server_fqdn = server_fqdn
            @full_path = full_path
            @semver = semver
            @component_name = component_name
          end

          def available?
            !!component&.file&.file&.exists?
          end

          def content
            return unless available?

            component.file.read
          end

          private

          attr_reader :server_fqdn, :full_path, :semver, :component_name

          def component
            ::Ci::Catalog::BundledResource.find_bundled_component(
              server_fqdn: server_fqdn,
              full_path: full_path,
              semver: semver,
              name: component_name
            )
          end
          strong_memoize_attr :component
        end
      end
    end
  end
end
