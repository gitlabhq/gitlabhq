class TreeDecorator < ApplicationDecorator
  decorates :tree

  def breadcrumbs(max_links = 2)
    if path
      part_path = ""
      parts = path.split("\/")

      yield(h.link_to("..", "#", :remote => :true)) if parts.count > max_links

      parts.each do |part|
        part_path = File.join(part_path, part) unless part_path.empty?
        part_path = part if part_path.empty?

        next unless parts.last(2).include?(part) if parts.count > max_links
        yield(h.link_to(h.truncate(part, :length => 40), h.tree_file_project_ref_path(project, ref, :path => part_path), :remote => :true))
      end
    end
  end

  def up_dir?
    !!path
  end

  def up_dir_path
    file = File.join(path, "..")
    h.tree_file_project_ref_path(project, ref, file)
  end

  def history_path
    h.project_commits_path(project, :path => path, :ref => ref)
  end
end
