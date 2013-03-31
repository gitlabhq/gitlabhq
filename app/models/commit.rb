class Commit
  include ActiveModel::Conversion
  include StaticModel
  extend ActiveModel::Naming

  # Safe amount of files with diffs in one commit to render
  # Used to prevent 500 error on huge commits by suppressing diff
  #
  DIFF_SAFE_SIZE = 100

  attr_accessor :raw

  def initialize(raw_commit)
    raise "Nil as raw commit passed" unless raw_commit

    @raw = raw_commit
  end

  def method_missing(m, *args, &block)
    @raw.send(m, *args, &block)
  end
end
