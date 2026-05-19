# frozen_string_literal: true

require_relative "auto_freeze/version"
require 'freezolite'

# Set frozen_string_literals: true when requiring gems.
module AutoFreeze
  GemError = Class.new(StandardError)

  class << self
    def setup!(included_gems: [], excluded_gems: [])
      if !included_gems.empty? && !excluded_gems.empty?
        raise ArgumentError, "Cannot use both included_gems: and excluded_gems: arguments"
      end

      # Freezolite uses File.fnmatch for its patterns.
      # It also uses load_iseq(<absolute_path>) callback for its around hook.
      # So to freeze gem, we need to find the absolute path using `Gem.path`.
      include_patterns = if included_gems.empty?
                           Gem.path.map { |path| File.join(path, "*.rb") }
                         else
                           included_gems.flat_map do |gem_name|
                             Gem::Specification.find_by_name(gem_name).full_require_paths.map do |require_path|
                               File.join(require_path, "*.rb")
                             end
                           rescue Gem::MissingSpecError => e
                             raise GemError, "Could not find '#{gem_name}'", cause: e
                           end
                         end

      exclude_patterns = excluded_gems.map do |gem_name|
        full_gem_name = Gem::Specification.find_by_name(gem_name).full_name

        File.join("**", full_gem_name, "**")
      rescue Gem::MissingSpecError => e
        raise GemError, "Could not find '#{gem_name}'", cause: e
      end

      freezolite_setup(
        patterns: include_patterns,
        exclude_patterns: exclude_patterns
      )
    end

    private

    def freezolite_setup(**kwargs)
      Freezolite.setup(**kwargs)
    end
  end
end
