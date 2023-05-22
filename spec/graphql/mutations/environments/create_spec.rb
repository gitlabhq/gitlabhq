# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Environments::Create, feature_category: :environment_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user).tap { |u| project.add_maintainer(u) } }
  let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }

  let(:user) { maintainer }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#resolve' do
    subject { mutation.resolve(project_path: project.full_path, name: name, external_url: external_url) }

    let(:name) { 'production' }
    let(:external_url) { 'https://gitlab.com/' }

    context 'when service execution succeeded' do
      it 'returns no errors' do
        expect(subject[:errors]).to be_empty
      end

      it 'creates the environment' do
        expect(subject[:environment][:name]).to eq(name)
        expect(subject[:environment][:external_url]).to eq(external_url)
      end
    end

    context 'when service cannot create the attribute' do
      let(:external_url) { 'http://${URL}' }

      it 'returns an error' do
        expect(subject)
          .to eq({
            environment: nil,
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
