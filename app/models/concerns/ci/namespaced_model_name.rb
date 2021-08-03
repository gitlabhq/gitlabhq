# frozen_string_literal: true

module Ci
  module NamespacedModelName
    extend ActiveSupport::Concern

    class_methods do
      def model_name
        @model_name ||= ActiveModel::Name.new(self, Ci)
      end
    end
  end
end
