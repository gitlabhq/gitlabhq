class MergeRequestDiffFile < ActiveRecord::Base
  include Gitlab::EncodingHelper

  belongs_to :merge_request_diff

  def utf8_diff
    return '' if diff.blank?

    encode_utf8(diff) if diff.respond_to?(:encoding)
  end

  def diff
    binary? ? super.unpack('m0').first : super
  end

  def to_hash
    keys = Gitlab::Git::Diff::SERIALIZE_KEYS - [:diff]

    as_json(only: keys).merge(diff: diff).with_indifferent_access
  end
end
