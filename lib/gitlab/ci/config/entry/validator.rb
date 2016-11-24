module Gitlab
  module Ci
    class Config
      module Entry
        class Validator < SimpleDelegator
          include ActiveModel::Validations
          include Entry::Validators

          def initialize(entry)
            super(entry)
            @entry = entry
          end

          def messages
            errors.full_messages.map do |error|
              "#{location} #{error}".downcase
            end
          end

          def self.name
            'Validator'
          end

          private

          def location
            predecessors = ancestors.map(&:key).compact
            predecessors.append(key_name).join(':')
          end

          def key_name
            if key.blank?
              @entry.class.name.demodulize.underscore.humanize
            else
              key
            end
          end
        end
      end
    end
  end
end
