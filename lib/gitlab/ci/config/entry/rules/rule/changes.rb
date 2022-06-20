# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Rules
          class Rule
            class Changes < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable

              validations do
                validates :config,
                          array_of_strings: true,
                          length: { maximum: 50, too_long: "has too many entries (maximum %{count})" }
              end
            end
          end
        end
      end
    end
  end
end
