module Gitlab
  module Ci
    class Config
      module Entry
        class Validator < SimpleDelegator
          include ActiveModel::Validations
          include Entry::Validators

          def initialize(entry)
            super(entry)
          end

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
end
