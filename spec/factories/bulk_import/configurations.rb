# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import_configuration, class: 'BulkImports::Configuration' do
    bulk_import

    url { 'https://gitlab.example' }
    access_token { 'token' }
  end
end
