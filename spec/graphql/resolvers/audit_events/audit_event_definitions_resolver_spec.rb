# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::AuditEvents::AuditEventDefinitionsResolver, feature_category: :audit_events do
  using RSpec::Parameterized::TableSyntax

  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  describe '#resolve' do
    let(:args) { {} }

    subject(:audit_event_definitions) { resolve(described_class, args: args, ctx: { current_user: current_user }) }

    it 'returns an array of audit event definitions' do
      expect(audit_event_definitions).to be_an(Array)
      expect(audit_event_definitions).to match_array(Gitlab::Audit::Type::Definition.definitions.values)
    end
  end
end
