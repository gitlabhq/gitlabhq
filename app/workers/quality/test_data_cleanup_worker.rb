# frozen_string_literal: true

module Quality
  class TestDataCleanupWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :quality_management
    urgency :low

    include CronjobQueue
    idempotent!

    KEEP_RECENT_DATA_DAY = 3
    GROUP_PATH_PATTERN = 'test-group-fulfillment'
    GROUP_OWNER_EMAIL_PATTERN = %w(test-user- gitlab-qa-user qa-user-).freeze

    # Remove test groups generated in E2E tests on gstg
    # rubocop: disable CodeReuse/ActiveRecord
    def perform
      return unless Gitlab.staging?

      Group.where('path like ?', "#{GROUP_PATH_PATTERN}%").where('created_at < ?', KEEP_RECENT_DATA_DAY.days.ago).each do |group|
        next unless GROUP_OWNER_EMAIL_PATTERN.any? { |pattern| group.owners.first.email.include?(pattern) }

        with_context(namespace: group, user: group.owners.first) do
          Groups::DestroyService.new(group, group.owners.first).execute
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
