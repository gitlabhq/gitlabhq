module Gitlab
  class ProjectTransfer
    def move_project(project_path, namespace_path_was, namespace_path)
      new_namespace_folder = File.join(root_dir, namespace_path)
      FileUtils.mkdir_p(new_namespace_folder) unless Dir.exist?(new_namespace_folder)
      from = File.join(root_dir, namespace_path_was, project_path)
      to = File.join(root_dir, namespace_path, project_path)
      move(from, to, "")
    end

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
      base_dir = root_dir unless base_dir
      from = File.join(base_dir, path_was)
      to = File.join(base_dir, path)
      FileUtils.mv(from, to)
    rescue Errno::ENOENT
      false
    end
  end
end
