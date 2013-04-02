class Tree
  attr_accessor :path, :tree, :ref

  def initialize(repository, sha, ref = nil, path = nil)
    @raw = Gitlab::Git::Tree.new(repository, sha, ref, path)
  end

  def invalid?
    @raw.nil?
  end

  def method_missing(m, *args, &block)
    @raw.send(m, *args, &block)
  end

  def respond_to?(method)
    return true if @raw.respond_to?(method)

    super
  end
end
