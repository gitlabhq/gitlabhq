# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      class Validator < SimpleDelegator
        include ActiveModel::Validations
        include Entry::Validators

        def messages
          errors.full_messages.map do |error|
            "#{location} #{error}".downcase.gsub(/jobs ([a-z\s]+) config should implement/) do
              "jobs #{::Regexp.last_match(1).tr(' ', '_')} config should implement"
            end
          end
        end

        def self.name
          'Validator'
        end
      end
    end
  end
end
