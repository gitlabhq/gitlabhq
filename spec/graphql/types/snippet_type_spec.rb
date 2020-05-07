# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Snippet'] do
  let_it_be(:user) { create(:user) }

  it 'has the correct fields' do
    expected_fields = [:id, :title, :project, :author,
                       :file_name, :description,
                       :visibility_level, :created_at, :updated_at,
                       :web_url, :raw_url, :ssh_url_to_repo, :http_url_to_repo,
                       :notes, :discussions, :user_permissions,
                       :description_html, :blob]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'authorizations' do
    specify { expect(described_class).to require_graphql_authorizations(:read_snippet) }
  end

  shared_examples 'response without repository URLs' do
    it 'does not respond with repository URLs' do
      expect(response['sshUrlToRepo']).to be_nil
      expect(response['httpUrlToRepo']).to be_nil
    end
  end

  shared_examples 'snippets with repositories' do
    context 'when snippet has repository' do
      let_it_be(:snippet) { create(:personal_snippet, :repository, :public, author: user) }

      it 'responds with repository URLs' do
        expect(response['sshUrlToRepo']).to eq(snippet.ssh_url_to_repo)
        expect(response['httpUrlToRepo']).to eq(snippet.http_url_to_repo)
      end
    end
  end

  shared_examples 'snippets without repositories' do
    context 'when snippet does not have a repository' do
      let_it_be(:snippet) { create(:personal_snippet, :public, author: user) }

      it_behaves_like 'response without repository URLs'
    end
  end

  describe 'Repository URLs' do
    let(:query) do
      %(
        {
          snippets {
            nodes {
              sshUrlToRepo
              httpUrlToRepo
            }
          }
        }
      )
    end
    let(:response) { subject.dig('data', 'snippets', 'nodes')[0] }

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'when RequestStore is disabled' do
      it_behaves_like 'snippets with repositories'
      it_behaves_like 'snippets without repositories'
    end

    context 'when RequestStore is enabled', :request_store do
      it_behaves_like 'snippets with repositories'
      it_behaves_like 'snippets without repositories'
    end
  end

  describe '#blob' do
    let(:query_blob) { subject.dig('data', 'snippets', 'edges')[0]['node']['blob'] }
    let(:query) do
      %(
        {
          snippets {
            edges {
              node {
                blob {
                  name
                  path
                }
              }
            }
          }
        }
      )
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'when snippet has repository' do
      let!(:snippet) { create(:personal_snippet, :repository, :public, author: user) }
      let(:blob) { snippet.blobs.first }

      it 'returns blob from the repository' do
        expect(query_blob['name']).to eq blob.name
        expect(query_blob['path']).to eq blob.path
      end
    end

    context 'when snippet does not have a repository' do
      let!(:snippet) { create(:personal_snippet, :public, author: user) }
      let(:blob) { snippet.blob }

      it 'returns SnippetBlob type' do
        expect(query_blob['name']).to eq blob.name
        expect(query_blob['path']).to eq blob.path
      end
    end
  end
end
