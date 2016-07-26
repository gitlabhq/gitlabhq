class Compare
  delegate :commits, :same, :head, :base, to: :@compare

  def self.decorate(compare, project)
    if compare.is_a?(Compare)
      compare
    else
      self.new(compare, project)
    end
  end

  def initialize(compare, project)
    @compare = compare
    @project = project
  end

  def diff_file_collection(diff_options:, diff_refs: nil)
    Gitlab::Diff::FileCollection::Compare.new(@compare,
      project: @project,
      diff_options: diff_options,
      diff_refs: diff_refs)
  end
end
