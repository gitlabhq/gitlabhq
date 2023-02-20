# frozen_string_literal: true
FactoryBot.define do
  factory :airflow_dags, class: '::Airflow::Dags' do
    sequence(:dag_name) { |n| "dag_name_#{n}" }

    project
  end
end
