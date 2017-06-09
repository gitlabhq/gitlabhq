class MergeRequestDiffFile < ActiveRecord::Base
  include Gitlab::EncodingHelper

  belongs_to :merge_request_diff

  def self.keys
    @keys ||= column_names.map(&:to_sym) - [:merge_request_diff_id, :relative_order]
  end

  def to_hash
    self.class.keys.each_with_object({}) do |key, hash|
      hash[key] = public_send(key)
    end
  end

  def utf8_diff
    return '' if diff.blank?

    encode_utf8(diff) if diff.respond_to?(:encoding)
  end
end
