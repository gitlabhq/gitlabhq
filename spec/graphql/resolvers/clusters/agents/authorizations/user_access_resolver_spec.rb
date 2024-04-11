# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Clusters::Agents::Authorizations::UserAccessResolver,
  feature_category: :deployment_management do
  include GraphqlHelpers

  it { expect(described_class.type).to eq(Types::Clusters::Agents::Authorizations::UserAccessType) }
  it { expect(described_class.null).to be_truthy }

  describe '#resolve' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user, maintainer_of: project) }

    let(:ctx) { { current_user: user } }

    subject { resolve(described_class, obj: project, ctx: ctx) }

    it 'calls the finder' do
      expect_next_instance_of(::Clusters::Agents::Authorizations::UserAccess::Finder,
        user, project: project) do |finder|
        expect(finder).to receive(:execute)
      end

      subject
    end
  end
end
