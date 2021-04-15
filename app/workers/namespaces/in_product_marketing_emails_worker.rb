# frozen_string_literal: true

module Namespaces
  class InProductMarketingEmailsWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :subgroups
    urgency :low

    def perform
      return if paid_self_managed_instance?
      return if setting_disabled?
      return if experiment_inactive?

      Namespaces::InProductMarketingEmailsService.send_for_all_tracks_and_intervals
    end

    private

    def paid_self_managed_instance?
      false
    end

    def setting_disabled?
      !Gitlab::CurrentSettings.in_product_marketing_emails_enabled
    end

    def experiment_inactive?
      Gitlab.com? && !Gitlab::Experimentation.active?(:in_product_marketing_emails)
    end
  end
end

Namespaces::InProductMarketingEmailsWorker.prepend_if_ee('EE::Namespaces::InProductMarketingEmailsWorker')
