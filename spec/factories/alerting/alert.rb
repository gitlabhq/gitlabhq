# frozen_string_literal: true

FactoryBot.define do
  factory :alerting_alert, class: 'Gitlab::Alerting::Alert' do
    project
    payload { {} }

    transient do
      metric_id { nil }

      after(:build) do |alert, evaluator|
        unless alert.payload.key?('startsAt')
          alert.payload['startsAt'] = Time.now.rfc3339
        end

        if metric_id = evaluator.metric_id
          alert.payload['labels'] ||= {}
          alert.payload['labels']['gitlab_alert_id'] = metric_id.to_s
        end
      end
    end

    skip_create
  end
end
