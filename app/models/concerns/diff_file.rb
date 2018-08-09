# frozen_string_literal: true

module DiffFile
  extend ActiveSupport::Concern

  def to_hash
    keys = Gitlab::Git::Diff::SERIALIZE_KEYS - [:diff]

    as_json(only: keys).merge(diff: diff).with_indifferent_access
  end
end
