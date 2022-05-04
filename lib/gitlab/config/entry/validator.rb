# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      class Validator < SimpleDelegator
        include ActiveModel::Validations
        include Entry::Validators

        def messages
          errors.full_messages.map do |error|
            "#{location} #{error}".downcase
          end
        end

        def self.name
          'Validator'
        end
      end
    end
  end
end
