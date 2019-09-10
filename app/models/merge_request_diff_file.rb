# frozen_string_literal: true

class MergeRequestDiffFile < ApplicationRecord
  include Gitlab::EncodingHelper
  include DiffFile

  belongs_to :merge_request_diff, inverse_of: :merge_request_diff_files

  def utf8_diff
    return '' if diff.blank?

    encode_utf8(diff) if diff.respond_to?(:encoding)
  end

  def diff
    content =
      if merge_request_diff&.stored_externally?
        merge_request_diff.opening_external_diff do |file|
          file.seek(external_diff_offset)
          force_encode_utf8(file.read(external_diff_size))
        end
      else
        super
      end

    binary? ? content.unpack1('m0') : content
  end
end
