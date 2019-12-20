# frozen_string_literal: true

module ActsAsPaginatedDiff
  # Comparisons going back to the repository will need proper batch
  # loading (https://gitlab.com/gitlab-org/gitlab/issues/32859).
  # For now, we're returning all the diffs available with
  # no pagination data.
  def diffs_in_batch(_batch_page, _batch_size, diff_options:)
    diffs(diff_options)
  end
end
