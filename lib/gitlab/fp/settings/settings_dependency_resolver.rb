# frozen_string_literal: true

module Gitlab
  module Fp
    module Settings
      class SettingsDependencyResolver
        # @param [Array] setting_names An array of setting names
        # @param [Hash] dependencies A hash of setting names to array of dependent setting names
        # @return [Array] An array of setting names + all recursive dependencies
        def self.resolve(setting_names, dependencies)
          result = []
          visited = Set.new
          queue = setting_names.clone

          until queue.empty?
            setting_name = queue.shift

            # Go to the next item in the queue if we've already seen this one
            next if visited.include?(setting_name)

            visited.add(setting_name)
            result.push(setting_name)

            setting_dependencies = dependencies[setting_name]
            queue.push(*setting_dependencies) if setting_dependencies
          end

          result
        end
      end
    end
  end
end
