# frozen_string_literal: true

FactoryBot.define do
  factory :issue_csv_import, class: 'Issues::CsvImport' do
    project
    user
  end
end
