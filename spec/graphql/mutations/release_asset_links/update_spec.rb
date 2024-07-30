# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::ReleaseAssetLinks::Update, feature_category: :release_orchestration do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:release) { create(:release, project: project, tag: 'v13.10') }
  let_it_be(:reporter) { create(:user, reporter_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }

  let_it_be(:name) { 'link name' }
  let_it_be(:url) { 'https://example.com/url' }
  let_it_be(:filepath) { '/permanent/path' }
  let_it_be(:link_type) { 'package' }

  let_it_be(:release_link) do
    create(
      :release_link,
      release: release,
      name: name,
      url: url,
      filepath: filepath,
      link_type: link_type
    )
  end

  let(:current_user) { developer }
  let(:mutation) { described_class.new(object: nil, context: query_context, field: nil) }

  let(:mutation_arguments) do
    {
      id: release_link.to_global_id
    }
  end

  shared_examples 'no changes to the link except for the' do |except_for|
    it 'does not change other link properties' do
      expect(updated_link.name).to eq(name) unless except_for == :name
      expect(updated_link.url).to eq(url) unless except_for == :url
      expect(updated_link.filepath).to eq(filepath) unless except_for == :filepath
      expect(updated_link.link_type).to eq(link_type) unless except_for == :link_type
    end
  end

  shared_examples 'validation error with messages' do |messages|
    it 'returns the updated link as nil' do
      expect(updated_link).to be_nil
    end

    it 'returns a validation error' do
      expect(subject[:errors]).to match_array(messages)
    end
  end

  describe '#ready?' do
    let(:current_user) { developer }

    subject(:ready) do
      mutation.ready?(**mutation_arguments)
    end

    context 'when link_type is included as an argument but is passed nil' do
      let(:mutation_arguments) { super().merge(link_type: nil) }

      it 'raises a validation error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'if the linkType argument is provided, it cannot be null')
      end
    end
  end

  describe '#resolve' do
    subject(:resolve) do
      mutation.resolve(**mutation_arguments)
    end

    let(:updated_link) { subject[:link] }

    context 'when the current user has access to update the link' do
      context 'name' do
        let(:mutation_arguments) { super().merge(name: updated_name) }

        context 'when a new name is provided' do
          let(:updated_name) { 'Updated name' }

          it 'updates the name' do
            expect(updated_link.name).to eq(updated_name)
          end

          it_behaves_like 'no changes to the link except for the', :name

          context 'with protected tag' do
            context 'when user has access to the protected tag' do
              let!(:protected_tag) { create(:protected_tag, :developers_can_create, name: '*', project: project) }

              it 'does not have errors' do
                subject

                expect(resolve).to include(errors: [])
              end
            end

            context 'when user does not have access to the protected tag' do
              let!(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: '*', project: project) }

              it 'raises a resource access error' do
                expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
              end
            end
          end
        end

        context 'when nil is provided' do
          let(:updated_name) { nil }

          it_behaves_like 'validation error with messages', ["Name can't be blank"]
        end
      end

      context 'url' do
        let(:mutation_arguments) { super().merge(url: updated_url) }

        context 'when a new URL is provided' do
          let(:updated_url) { 'https://example.com/updated/link' }

          it 'updates the url' do
            expect(updated_link.url).to eq(updated_url)
          end

          it_behaves_like 'no changes to the link except for the', :url
        end

        context 'when nil is provided' do
          let(:updated_url) { nil }

          it_behaves_like 'validation error with messages', ["Url can't be blank", "Url must be a valid URL"]
        end
      end

      context 'filepath' do
        let(:mutation_arguments) { super().merge(filepath: updated_filepath) }

        context 'when a new filepath is provided' do
          let(:updated_filepath) { '/updated/filepath' }

          it 'updates the filepath' do
            expect(updated_link.filepath).to eq(updated_filepath)
          end

          it_behaves_like 'no changes to the link except for the', :filepath
        end

        context 'when nil is provided' do
          let(:updated_filepath) { nil }

          it 'updates the filepath to nil' do
            expect(updated_link.filepath).to be_nil
          end
        end
      end

      context 'link_type' do
        let(:mutation_arguments) { super().merge(link_type: updated_link_type) }

        context 'when a new link type is provided' do
          let(:updated_link_type) { 'image' }

          it 'updates the link type' do
            expect(updated_link.link_type).to eq(updated_link_type)
          end

          it_behaves_like 'no changes to the link except for the', :link_type
        end

        # Test cases not included:
        # - when nil is provided, because this validated by #ready?
        # - when an invalid type is provided, because this is validated by the GraphQL schema
      end
    end

    context 'when the current user does not have access to update the link' do
      let(:current_user) { reporter }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context "when the link doesn't exist" do
      let(:mutation_arguments) do
        super().merge(id: global_id_of(id: non_existing_record_id, model_name: "Releases::Link"))
      end

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
