module Gitlab
  module Diff
    def self.available_paths(diffs)
      return [] unless diffs
      paths = diffs.reduce([]) do |paths, diff|
        paths << diff.new_path
        paths + parent_directories(diff.new_path)
      end
      paths.uniq
    end

    private

    def self.parent_directories(path)
      top_level_path = File.dirname(path)
      return [] if top_level_path.in? %w(. /)

      [top_level_path] + parent_directories(top_level_path)
    end
  end
end
