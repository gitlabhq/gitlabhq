# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Wikis::WikiPageResolver, feature_category: :wiki do
  include GraphqlHelpers

  describe '#resolve' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :private, developers: user) }

    let(:slug) { wiki_page_meta.slugs.first.slug }

    context 'for project wikis' do
      let_it_be(:wiki_page_meta) { create(:wiki_page_meta, :for_wiki_page, container: project) }

      subject(:resolved_wiki_page) do
        resolve_wiki_page('slug' => slug, 'project_id' => global_id_of(project))
      end

      it { is_expected.to eq(wiki_page_meta) }

      context 'when page does not exist' do
        let(:slug) { 'foobar' }

        it { is_expected.to be_nil }
      end
    end

    context 'when both project_id and namespace_id are passed' do
      let(:group) { build_stubbed(:group) }

      subject(:resolved_wiki_page) do
        resolve_wiki_page(
          'slug' => 'foobar',
          'project_id' => global_id_of(project),
          'namespace_id' => global_id_of(group)
        )
      end

      it 'raises an ArgumentError' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError) do
          resolved_wiki_page
        end
      end
    end
  end

  private

  def resolve_wiki_page(args = {})
    resolve(described_class, args: args, ctx: { current_user: user })
  end
end
