# frozen_string_literal: true

module BlobLike
  extend ActiveSupport::Concern
  include Gitlab::BlobHelper

  def id
    raise NotImplementedError
  end

  def name
    raise NotImplementedError
  end

  def path
    raise NotImplementedError
  end

  def size
    0
  end

  def data
    nil
  end

  def mode
    nil
  end

  def binary_in_repo?
    false
  end

  def load_all_data!(repository)
    # No-op
  end

  def truncated?
    false
  end

  def external_storage
    nil
  end

  def external_size
    nil
  end
end
