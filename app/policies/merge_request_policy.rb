# frozen_string_literal: true

class MergeRequestPolicy < IssuablePolicy
  rule { locked }.policy do
    prevent :reopen_merge_request
  end
end
