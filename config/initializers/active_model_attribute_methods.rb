# frozen_string_literal: true

if ::Gitlab.next_rails?
  # Override the method to use Set instead of Array:
  #
  # https://github.com/rails/rails/blob/v7.1.5.1/activemodel/lib/active_model/attribute_methods.rb#L398
  #
  # Otherwise, the background migrations are very slow.
  # Explanation: https://gitlab.com/gitlab-org/gitlab/-/issues/495067#note_2260634049
  module ActiveModel
    module AttributeMethods
      module ClassMethods
        def aliases_by_attribute_name
          @aliases_by_attribute_name ||= Hash.new { |h, k| h[k] = Set.new }
        end
      end
    end
  end
end
