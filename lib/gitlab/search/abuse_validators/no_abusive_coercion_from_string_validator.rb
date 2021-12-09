# frozen_string_literal: true

module Gitlab
  module Search
    module AbuseValidators
      class NoAbusiveCoercionFromStringValidator < ActiveModel::EachValidator
        def validate_each(instance, attribute, value)
          if value.present? && !value.is_a?(String)
            instance.errors.add attribute, "abusive coercion from string detected"
          end
        end
      end
    end
  end
end
