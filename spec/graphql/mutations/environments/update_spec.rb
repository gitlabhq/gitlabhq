# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Environments::Update, feature_category: :environment_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:reporter) { create(:user) }

  let(:user) { maintainer }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_reporter(reporter)
  end

  describe '#resolve' do
    subject { mutation.resolve(id: environment_id, external_url: external_url) }

    let(:environment_id) { environment.to_global_id }
    let(:external_url) { 'https://gitlab.com/' }

    context 'when service execution succeeded' do
      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end

      it 'updates the environment' do
        expect(subject[:environment][:external_url]).to eq(external_url)
      end
    end

    context 'when service cannot update the attribute' do
      let(:external_url) { 'http://${URL}' }

      it 'returns an error' do
        expect(subject)
          .to eq({
            environment: environment,
            errors: ['External url URI is invalid']
          })
      end
    end

    context 'when user is reporter who does not have permission to access the environment' do
      let(:user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR)
      end
    end
  end
end
