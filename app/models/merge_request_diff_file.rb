class MergeRequestDiffFile < ActiveRecord::Base
  include Gitlab::EncodingHelper

  belongs_to :merge_request_diff

  def utf8_diff
    return '' if diff.blank?

    encode_utf8(diff) if diff.respond_to?(:encoding)
  end
end
