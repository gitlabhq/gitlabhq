# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['WikiPage'], feature_category: :wiki do
  include GraphqlHelpers

  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :private, developers: developer) }
  let_it_be(:wiki_page_meta) { create(:wiki_page_meta, :for_wiki_page, container: project) }

  it 'has the correct fields' do
    expected_fields = [:id, :title, :notes, :discussions, :commenters, :user_permissions, :web_url, :name]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe 'permissions' do
    let(:query) do
      %(
        {
          wikiPage(slug: "#{wiki_page_meta.slugs.first.slug}", projectId: "#{global_id_of(project)}") {
            id
            title
            webUrl
            name
          }
        }
      )
    end

    subject(:response) do
      GitlabSchema.execute(query, context: { current_user: current_user }).as_json['data']['wikiPage']
    end

    context 'when user is a member of the project' do
      let(:current_user) { developer }

      it 'has wiki page title' do
        expect(response['title']).to eq(wiki_page_meta.title)
      end
    end

    context 'when user is not logged in' do
      let(:current_user) { nil }

      it 'returns wiki page as nil' do
        expect(response).to be_nil
      end
    end

    context 'when user is not a member of the project' do
      let(:current_user) { build(:user) }

      it 'returns wiki page as nil' do
        expect(response).to be_nil
      end
    end
  end

  describe 'authorizations' do
    specify { expect(described_class).to require_graphql_authorizations(:read_wiki) }
  end
end
