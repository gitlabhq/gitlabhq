# frozen_string_literal: true

FactoryBot.define do
  factory :callout, class: 'Users::Callout' do
    feature_name { :gke_cluster_integration }

    user
  end
end
