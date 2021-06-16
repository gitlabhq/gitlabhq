# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Snippet'] do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  it 'has the correct fields' do
    expected_fields = [:id, :title, :project, :author,
                       :file_name, :description,
                       :visibility_level, :created_at, :updated_at,
                       :web_url, :raw_url, :ssh_url_to_repo, :http_url_to_repo,
                       :notes, :discussions, :user_permissions,
                       :description_html, :blobs]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'blobs field' do
    subject { described_class.fields['blobs'] }

    it 'returns blobs' do
      is_expected.to have_graphql_type(Types::Snippets::BlobType.connection_type)
      is_expected.to have_graphql_resolver(Resolvers::Snippets::BlobsResolver)
    end
  end

  describe '#user_permissions' do
    let_it_be(:snippet) { create(:personal_snippet, :repository, :public, author: user) }

    it 'can resolve the snippet permissions' do
      expect(resolve_field(:user_permissions, snippet)).to eq(snippet)
    end
  end

  context 'when restricted visibility level is set to public' do
    let_it_be(:snippet) { create(:personal_snippet, :repository, :public, author: user) }

    let(:current_user) { user }
    let(:query) do
      %(
        {
          snippets {
            nodes {
              author {
                id
              }
            }
          }
        }
      )
    end

    let(:response) { subject.dig('data', 'snippets', 'nodes')[0] }

    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    before do
      stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])
    end

    it 'returns snippet author' do
      expect(response['author']).to be_present
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it 'returns snippet author as nil' do
        expect(response['author']).to be_nil
      end
    end
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

  describe '#blobs' do
    let_it_be(:snippet) { create(:personal_snippet, :public, author: user) }

    let(:query_blobs) { subject.dig('data', 'snippets', 'nodes')[0].dig('blobs', 'nodes') }
    let(:paths) { [] }
    let(:query) do
      %(
        {
          snippets {
            nodes {
              blobs(paths: #{paths}) {
                nodes {
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

    shared_examples 'an array' do
      it 'returns an array of snippet blobs' do
        expect(query_blobs).to be_an(Array)
      end
    end

    context 'when snippet does not have a repository' do
      let(:blob) { snippet.blob }

      it_behaves_like 'an array'

      it 'contains the first blob from the snippet' do
        expect(query_blobs.first['name']).to eq blob.name
        expect(query_blobs.first['path']).to eq blob.path
      end
    end

    context 'when snippet has repository' do
      let_it_be(:snippet) { create(:personal_snippet, :repository, :public, author: user) }

      let(:blobs) { snippet.blobs }

      it_behaves_like 'an array'

      it 'contains all the blobs from the repository' do
        resulting_blobs_names = query_blobs.map { |b| b['name'] }

        expect(resulting_blobs_names).to match_array(blobs.map(&:name))
      end

      context 'when specific path is set' do
        let(:paths) { ['CHANGELOG'] }

        it_behaves_like 'an array'

        it 'returns specific files' do
          resulting_blobs_names = query_blobs.map { |b| b['name'] }

          expect(resulting_blobs_names).to match(paths)
        end
      end
    end
  end

  def snippet_query_for(field:)
    %(
      {
        snippets {
          nodes {
            #{field} {
              name
              path
            }
          }
        }
      }
    )
  end
end
