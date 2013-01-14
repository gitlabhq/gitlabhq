class TreeDecorator < ApplicationDecorator
  decorates :tree

  def breadcrumbs(max_links = 2)
    if path
      part_path = ""
      parts = path.split("\/")

      yield('..', nil) if parts.count > max_links

      parts.each do |part|
        part_path = File.join(part_path, part) unless part_path.empty?
        part_path = part if part_path.empty?

        next unless parts.last(2).include?(part) if parts.count > max_links
        yield(part, h.tree_join(ref, part_path))
      end
    end
  end

  def up_dir?
    path.present?
  end

  def up_dir_path
    file = File.join(path, "..")
    h.tree_join(ref, file)
  end

  def readme
    @readme ||= contents.find { |c| c.is_a?(Grit::Blob) and c.name =~ /^readme/i }
  end
end
