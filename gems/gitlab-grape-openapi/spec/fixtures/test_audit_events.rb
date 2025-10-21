# frozen_string_literal: true

require 'grape'

module API
  class TestAuditEvents < Grape::API
    resources :audit_events do
      desc 'Get the list of audit events' do
        detail 'Returns a list of audit events.'
        tags %w[hello world]
      end
      get do
      end

      desc 'Define some more tags' do
        detail 'This is a test secondary API endpoint.'
        tags %w[hello world foo bar baz]
      end
      get do
      end

      # rubocop:disable API/DescriptionTags,API/DescriptionDetail -- Needed to test this edge case
      desc 'Define endpoint with no tags' do
        detail 'This is an endpoint with no tags!'
      end
      get do
      end
      # rubocop:enable API/DescriptionTags,API/DescriptionDetail
    end
  end
end
