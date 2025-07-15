# frozen_string_literal: true

module Gitlab
  module Graphql
    module VersionFilter
      class FutureFieldFilter < GraphQL::Language::Visitor
        attr_reader :contain_future_fields

        def initialize(...)
          @contain_future_fields = false

          super
        end

        IntroducedDirective.locations.each do |location|
          define_method(:"on_#{location.downcase}") do |node, parent|
            if future_field?(node)
              @contain_future_fields = true
              return super(DELETE_NODE, parent)
            end

            super(node, parent)
          end
        end

        private

        def future_field?(node)
          version = introduced_version(node)

          return false if version.blank?

          ::Gitlab::VersionInfo.parse(version) > Gitlab.version_info
        end

        def introduced_version(node)
          directive = node.try(:directives)&.find { |d| d.name == IntroducedDirective.graphql_name }

          return if directive.blank?

          directive.arguments.find { |argument| argument.name == 'version' }&.value
        end
      end
    end
  end
end
