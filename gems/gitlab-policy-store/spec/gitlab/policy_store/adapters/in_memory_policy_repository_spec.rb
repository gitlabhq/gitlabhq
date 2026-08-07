# frozen_string_literal: true

RSpec.describe Gitlab::PolicyStore::Adapters::InMemoryPolicyRepository do
  let(:organization_id) { 1 }
  let(:namespace_id) { 10 }

  subject(:repository) { described_class.new }

  it_behaves_like 'a policy repository'
end
