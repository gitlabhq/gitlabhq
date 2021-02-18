# frozen_string_literal: true

class MergeRequestDiffFile < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning

  include BulkInsertSafe
  include Gitlab::EncodingHelper
  include DiffFile

  belongs_to :merge_request_diff, inverse_of: :merge_request_diff_files
  alias_attribute :index, :relative_order

  scope :by_paths, ->(paths) do
    where("new_path in (?) OR old_path in (?)", paths, paths)
  end

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

    return content unless binary?

    # If the data isn't valid base64, return it as-is, since it's almost certain
    # to be a valid diff. Parsing it as a diff will fail if it's something else.
    #
    # https://gitlab.com/gitlab-org/gitlab/-/issues/240921
    begin
      content.unpack1('m0')
    rescue ArgumentError
      content
    end
  end
end
