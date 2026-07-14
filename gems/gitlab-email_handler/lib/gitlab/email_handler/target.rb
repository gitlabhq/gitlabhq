# frozen_string_literal: true

module Gitlab
  module EmailHandler
    # The identified target of an incoming email: the kind of resource that owns
    # it and the value that locates it. This is a plain value object with no
    # knowledge of how the target is later resolved or routed.
    #
    # `kind` is one of:
    #   :project_id, :namespace_id, :route, :service_desk_custom_email
    Target = Data.define(:kind, :value) do
      def self.project_id(value)
        new(kind: :project_id, value: value)
      end

      def self.namespace_id(value)
        new(kind: :namespace_id, value: value)
      end

      def self.route(path)
        new(kind: :route, value: path.to_s.split('/').first)
      end

      def self.service_desk_custom_email(value)
        new(kind: :service_desk_custom_email, value: value)
      end
    end
  end
end
