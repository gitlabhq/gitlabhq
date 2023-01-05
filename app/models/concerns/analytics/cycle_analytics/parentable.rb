# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    module Parentable
      extend ActiveSupport::Concern

      included do
        belongs_to :namespace, class_name: 'Namespace', foreign_key: :group_id, optional: false # rubocop: disable Rails/InverseOf

        validate :ensure_namespace_type

        def ensure_namespace_type
          return if namespace.nil?
          return if namespace.is_a?(::Namespaces::ProjectNamespace) || namespace.is_a?(::Group)

          errors.add(:namespace, s_('CycleAnalytics|the assigned object is not supported'))
        end
      end
    end
  end
end
