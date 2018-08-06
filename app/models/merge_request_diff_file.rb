# frozen_string_literal: true

class MergeRequestDiffFile < ActiveRecord::Base
  include Gitlab::EncodingHelper
  include DiffFile

  belongs_to :merge_request_diff

  def utf8_diff
    return '' if diff.blank?

    encode_utf8(diff) if diff.respond_to?(:encoding)
  end

  def diff
    binary? ? super.unpack('m0').first : super
  end
end
