# frozen_string_literal: true

module Integrations
  class GroupMentionWorker
    include ApplicationWorker

    idempotent!
    feature_category :integrations
    deduplicate :until_executed
    data_consistency :delayed
    urgency :low

    worker_has_external_dependencies!

    def perform(args)
      args = args.with_indifferent_access

      mentionable_type = args[:mentionable_type]
      mentionable_id = args[:mentionable_id]
      hook_data = args[:hook_data]
      is_confidential = args[:is_confidential]

      mentionable = case mentionable_type
                    when 'Issue'
                      Issue.find(mentionable_id)
                    when 'MergeRequest'
                      MergeRequest.find(mentionable_id)
                    end

      if mentionable.nil?
        Sidekiq.logger.error(
          message: 'Integrations::GroupMentionWorker: mentionable not supported',
          mentionable_type: mentionable_type,
          mentionable_id: mentionable_id
        )
        return
      end

      Integrations::GroupMentionService.new(mentionable, hook_data: hook_data, is_confidential: is_confidential).execute
    end
  end
end
