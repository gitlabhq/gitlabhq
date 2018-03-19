class DiffsEntity < Grape::Entity
  expose :real_size

  expose :added_lines do |diffs|
    diffs.diff_files.sum(&:added_lines)
  end

  expose :removed_lines do |diffs|
    diffs.diff_files.sum(&:removed_lines)
  end

  expose :diff_files, using: DiffFileEntity
end
