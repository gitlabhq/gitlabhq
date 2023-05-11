# frozen_string_literal: true

module SshKeys
  class UpdateLastUsedAtWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executed
    data_consistency :sticky

    feature_category :source_code_management

    def perform(key_id)
      key = Key.find_by_id(key_id)

      return unless key

      Keys::LastUsedService.new(key).execute
    end
  end
end
