# frozen_string_literal: true

module Gitlab
  module DependencyLinker
    class CargoTomlLinker < BaseLinker
      self.file_type = :cargo_toml

      def link
        return highlighted_text unless toml

        super
      end

      private

      def link_dependencies
        link_dependencies_at("dependencies")
        link_dependencies_at("dev-dependencies")
        link_dependencies_at("build-dependencies")
      end

      def link_dependencies_at(type)
        dependencies = toml[type]
        return unless dependencies

        dependencies.each do |name, value|
          link_toml(name, value, type) do |name|
            "https://crates.io/crates/#{name}"
          end
        end
      end

      def link_toml(key, value, type, &url_proc)
        if value.is_a? String
          link_regex(/^(?<name>#{key})\s*=\s*"#{value}"/, &url_proc)
        else
          link_regex(/^\[#{type}\.(?<name>#{key})]/, &url_proc)
        end
      end

      def toml
        @toml ||= TomlRB.parse(plain_text) rescue nil
      end
    end
  end
end
