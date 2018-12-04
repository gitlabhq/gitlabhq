# frozen_string_literal: true

module Gitlab
  module LanguageData
    EXTENSION_MUTEX = Mutex.new

    class << self
      include Gitlab::Utils::StrongMemoize

      def extensions
        EXTENSION_MUTEX.synchronize do
          strong_memoize(:extensions) do
            Set.new.tap do |set|
              YAML.load_file(Rails.root.join('vendor', 'languages.yml')).each do |_name, details|
                details['extensions']&.each do |ext|
                  next unless ext.start_with?('.')

                  set << ext.downcase
                end
              end
            end
          end
        end
      end

      def clear_extensions!
        EXTENSION_MUTEX.synchronize do
          clear_memoization(:extensions)
        end
      end
    end
  end
end
