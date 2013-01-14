class Tree
  include Linguist::BlobHelper

  attr_accessor :path, :tree, :ref

  delegate  :contents, :basename, :name, :data, :mime_type,
            :mode, :size, :text?, :colorize, to: :tree

  def initialize(raw_tree, ref = nil, path = nil)
    @ref, @path = ref, path
    @tree = if path.present?
              raw_tree / path
            else
              raw_tree
            end
  end

  def is_blob?
    tree.is_a?(Grit::Blob)
  end

  def invalid?
    tree.nil?
  end

  def empty?
    data.blank?
  end
end
