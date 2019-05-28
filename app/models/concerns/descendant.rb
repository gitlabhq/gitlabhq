# frozen_string_literal: true

module Descendant
  extend ActiveSupport::Concern

  class_methods do
    def supports_nested_objects?
      Gitlab::Database.postgresql?
    end
  end
end
