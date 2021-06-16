# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['SnippetBlobViewer'] do
  let_it_be(:snippet) { create(:personal_snippet, :repository) }
  let_it_be(:blob) { snippet.repository.blob_at('HEAD', 'files/images/6049019_460s.jpg') }

  it 'has the correct fields' do
    expected_fields = [:type, :load_async, :too_large, :collapsed,
                       :render_error, :file_type, :loading_partial_name]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  it { expect(described_class.fields['type'].type).to be_non_null }
  it { expect(described_class.fields['loadAsync'].type).to be_non_null }
  it { expect(described_class.fields['collapsed'].type).to be_non_null }
  it { expect(described_class.fields['tooLarge'].type).to be_non_null }
  it { expect(described_class.fields['renderError'].type).not_to be_non_null }
  it { expect(described_class.fields['fileType'].type).to be_non_null }
  it { expect(described_class.fields['loadingPartialName'].type).to be_non_null }

  shared_examples 'nil field converted to false' do
    subject { GitlabSchema.execute(query, context: { current_user: snippet.author }).as_json }

    before do
      allow_next_instance_of(SnippetPresenter) do |instance|
        allow(instance).to receive(:blob).and_return(blob)
      end
    end

    it 'returns false' do
      snippet_blob = subject.dig('data', 'snippets', 'edges').first.dig('node', 'blobs', 'nodes').find { |b| b['path'] == blob.path }

      expect(snippet_blob['path']).to eq blob.path
      expect(blob_attribute).to be_nil
      expect(snippet_blob['simpleViewer'][attribute]).to eq false
    end
  end

  describe 'collapsed' do
    it_behaves_like 'nil field converted to false' do
      let(:query) do
        %(
          query {
            snippets(ids: "#{snippet.to_global_id}") {
              edges {
                node {
                  blobs {
                    nodes {
                      path
                      simpleViewer {
                        collapsed
                      }
                    }
                  }
                }
              }
            }
          }
        )
      end

      let(:attribute) { 'collapsed' }
      let(:blob_attribute) { blob.simple_viewer.collapsed? }
    end
  end

  describe 'tooLarge' do
    it_behaves_like 'nil field converted to false' do
      let(:query) do
        %(
          query {
            snippets(ids: "#{snippet.to_global_id}") {
              edges {
                node {
                  blobs {
                    nodes {
                      path
                      simpleViewer {
                        tooLarge
                      }
                    }
                  }
                }
              }
            }
          }
        )
      end

      let(:attribute) { 'tooLarge' }
      let(:blob_attribute) { blob.simple_viewer.too_large? }
    end
  end
end
