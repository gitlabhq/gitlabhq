# frozen_string_literal: true

FactoryBot.define do
  factory :project_topic, class: 'Projects::ProjectTopic' do
    association :project, factory: :project
    association :topic, factory: :topic
  end
end
