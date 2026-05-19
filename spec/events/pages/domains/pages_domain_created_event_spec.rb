# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../app/events/pages/domains/pages_domain_created_event'
require_relative '../../../support/shared_examples/events/event_with_schema_shared_examples'

RSpec.describe Pages::Domains::PagesDomainCreatedEvent, feature_category: :pages do
  it_behaves_like 'an event with schema',
    valid_data: { project_id: 1, namespace_id: 2, root_namespace_id: 3 },
    missing_required: %i[project_id namespace_id root_namespace_id],
    invalid_types: { project_id: 'not_an_integer', domain: 123 }

  describe '#schema' do
    context 'with valid optional fields' do
      it 'accepts domain_id and domain' do
        data = { project_id: 1, namespace_id: 2, root_namespace_id: 3, domain_id: 4, domain: 'example.com' }

        expect { described_class.new(data: data) }.not_to raise_error
      end
    end
  end
end
