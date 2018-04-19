class DiffsEntity < Grape::Entity
  expose :real_size

  expose :branch_name do |diffs|
    options[:merge_request]&.source_branch
  end

  expose :commit do |diffs|
    options[:commit]
  end

  expose :start_version do |diffs|
    options[:start_version]
  end

  expose :latest_diff do |diffs|
    options[:latest_diff]
  end

  expose :added_lines do |diffs|
    diffs.diff_files.sum(&:added_lines)
  end

  expose :removed_lines do |diffs|
    diffs.diff_files.sum(&:removed_lines)
  end

  expose :diff_files, using: DiffFileEntity

  expose :merge_request_diffs, if: -> (_, options) { options[:merge_request_diffs] } do |diffs|
    options[:merge_request_diffs].as_json
  end

  # Simon: Can we not expose this if merge_request_diffs are <= 1?
  expose :merge_request_diffs, using: MergeRequestDiffEntity, if: -> (_, options) { options[:merge_request_diffs].any? } do |diffs|
    options[:merge_request_diffs]
  end
end
