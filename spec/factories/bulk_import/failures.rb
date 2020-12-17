# frozen_string_literal: true

require 'securerandom'

FactoryBot.define do
  factory :bulk_import_failure, class: 'BulkImports::Failure' do
    association :entity, factory: :bulk_import_entity

    pipeline_class { 'BulkImports::TestPipeline' }
    exception_class { 'StandardError' }
    exception_message { 'Standard Error Message' }
    correlation_id_value { SecureRandom.uuid }
  end
end
