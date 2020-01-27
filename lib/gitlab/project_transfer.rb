# frozen_string_literal: true

module Gitlab
  # This class is used to move local, unhashed files owned by projects to their new location
  class ProjectTransfer
    # nil parent_path (or parent_path_was) represents a root namespace
    def move_namespace(path, parent_path_was, parent_path)
      parent_path_was ||= ''
      parent_path ||= ''
      new_parent_folder = File.join(root_dir, parent_path)
      FileUtils.mkdir_p(new_parent_folder)
      from = File.join(root_dir, parent_path_was, path)
      to = File.join(root_dir, parent_path, path)
      move(from, to, "")
    end

    alias_method :move_project, :move_namespace

    def rename_project(path_was, path, namespace_path)
      base_dir = File.join(root_dir, namespace_path)
      move(path_was, path, base_dir)
    end

    def rename_namespace(path_was, path)
      move(path_was, path)
    end

    def root_dir
      raise NotImplementedError
    end

    private

    def move(path_was, path, base_dir = nil)
      base_dir ||= root_dir
      from = File.join(base_dir, path_was)
      to = File.join(base_dir, path)
      FileUtils.mv(from, to)
    rescue Errno::ENOENT
      false
    end
  end
end
