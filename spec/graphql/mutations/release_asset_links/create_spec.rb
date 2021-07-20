# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ReleaseAssetLinks::Create do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:release) { create(:release, project: project, tag: 'v13.10') }
  let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }

  let(:current_user) { developer }
  let(:context) { { current_user: current_user } }
  let(:project_path) { project.full_path }
  let(:tag) { release.tag }
  let(:name) { 'awesome-app.dmg' }
  let(:url) { 'https://example.com/download/awesome-app.dmg' }
  let(:filepath) { '/binaries/awesome-app.dmg' }

  let(:args) do
    {
      project_path: project_path,
      tag_name: tag,
      name: name,
      direct_asset_path: filepath,
      url: url
    }
  end

  let(:last_release_link) { release.links.last }

  describe '#resolve' do
    subject do
      resolve(described_class, obj: project, args: args, ctx: context)
    end

    context 'when the user has access and no validation errors occur' do
      it 'creates a new release asset link', :aggregate_failures do
        expect(subject).to eq({
          link: release.reload.links.first,
          errors: []
        })

        expect(release.links.length).to be(1)

        expect(last_release_link.name).to eq(name)
        expect(last_release_link.url).to eq(url)
        expect(last_release_link.filepath).to eq(filepath)
      end
    end

    context 'with protected tag' do
      context 'when user has access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

        it 'does not have errors' do
          expect(subject).to include(errors: [])
        end
      end

      context 'when user does not have access to the protected tag' do
        let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

        it 'has an access error' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
        end
      end
    end

    context "when the user doesn't have access to the project" do
      let(:current_user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context "when the project doesn't exist" do
      let(:project_path) { 'project/that/does/not/exist' }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context "when a validation errors occur" do
      shared_examples 'returns errors-as-data' do |expected_messages|
        it { expect(subject[:errors]).to eq(expected_messages) }
      end

      context "when the release doesn't exist" do
        let(:tag) { "nonexistent-tag" }

        it_behaves_like 'returns errors-as-data', ['Release with tag "nonexistent-tag" was not found']
      end

      context 'when the URL is badly formatted' do
        let(:url) { 'badly-formatted-url' }

        it_behaves_like 'returns errors-as-data', ["Url is blocked: Only allowed schemes are http, https, ftp"]
      end

      context 'when the name is not provided' do
        let(:name) { '' }

        it_behaves_like 'returns errors-as-data', ["Name can't be blank"]
      end

      context 'when the link already exists' do
        let!(:existing_release_link) do
          create(:release_link, release: release, name: name, url: url, filepath: filepath)
        end

        it_behaves_like 'returns errors-as-data', [
          "Url has already been taken",
          "Name has already been taken",
          "Filepath has already been taken"
        ]
      end
    end
  end
end
