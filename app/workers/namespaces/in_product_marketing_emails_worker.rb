# frozen_string_literal: true

module Namespaces
  class InProductMarketingEmailsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :subgroups
    urgency :low

    def perform
      return unless Gitlab::CurrentSettings.in_product_marketing_emails_enabled
      return if Gitlab.com? && !Gitlab::Experimentation.active?(:in_product_marketing_emails)

      Namespaces::InProductMarketingEmailsService.send_for_all_tracks_and_intervals
    end
  end
end
