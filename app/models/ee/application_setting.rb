module EE
  # ApplicationSetting EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `ApplicationSetting` model
  module ApplicationSetting
    extend ActiveSupport::Concern

    prepended do
      include IgnorableColumn

      ignore_column :minimum_mirror_sync_time

      validates :shared_runners_minutes,
                numericality: { greater_than_or_equal_to: 0 }

      validates :mirror_max_delay,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: :mirror_max_delay_in_minutes }

      validates :mirror_max_capacity,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

      validates :mirror_capacity_threshold,
                presence: true,
                numericality: { allow_nil: true, only_integer: true, greater_than: 0 }

      validate :mirror_capacity_threshold_less_than
    end

    module ClassMethods
      def defaults
        super.merge(
          authorized_keys_enabled: true, # TODO default to false if the instance is configured to use AuthorizedKeysCommand
          elasticsearch_url: ENV['ELASTIC_URL'] || 'http://localhost:9200',
          elasticsearch_aws: false,
          elasticsearch_aws_region: ENV['ELASTIC_REGION'] || 'us-east-1',
          repository_size_limit: 0,
          mirror_max_delay: Settings.gitlab['mirror_max_delay'],
          mirror_max_capacity: Settings.gitlab['mirror_max_capacity'],
          mirror_capacity_threshold: Settings.gitlab['mirror_capacity_threshold']
        )
      end
    end

    def should_check_namespace_plan?
      check_namespace_plan? && (::Gitlab.com? || Rails.env.development?)
    end

    private

    def mirror_max_delay_in_minutes
      ::Gitlab::Mirror.min_delay_upper_bound / 60
    end

    def mirror_capacity_threshold_less_than
      return unless mirror_max_capacity && mirror_capacity_threshold

      if mirror_capacity_threshold > mirror_max_capacity
        errors.add(:mirror_capacity_threshold, "Project's mirror capacity threshold can't be higher than it's maximum capacity")
      end
    end
  end
end
