# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI/CD Catalog details page', :js, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository, namespace: namespace) }

  shared_examples_for 'has correct viewing permissions' do
    context 'when the resource is published' do
      let(:published_catalog_resource) { create(:ci_catalog_resource, :published, project: project) }

      before do
        visit explore_catalog_path(published_catalog_resource)
      end

      it 'navigates to the details page' do
        expect(page).to have_content('Readme')
      end
    end

    context 'when the resource is not published' do
      let(:unpublished_catalog_resource) { create(:ci_catalog_resource, project: project, state: :unpublished) }

      before do
        visit explore_catalog_path(unpublished_catalog_resource)
      end

      it 'returns a 404' do
        expect(page).to have_title('Not Found')
        expect(page).to have_content('Page not found')
      end
    end
  end

  context 'when authenticated' do
    before do
      sign_in(user)
    end

    it_behaves_like 'has correct viewing permissions'
  end

  context 'when unauthenticated' do
    it_behaves_like 'has correct viewing permissions'
  end
end
