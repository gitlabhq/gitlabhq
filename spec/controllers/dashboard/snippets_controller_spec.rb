# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::SnippetsController do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    it_behaves_like 'paginated collection' do
      let(:collection) { Snippet.all }

      before do
        create(:personal_snippet, :public, author: user)
      end
    end

    it 'fetches snippet counts via the snippet count service' do
      service = double(:count_service, execute: {})
      expect(Snippets::CountService)
        .to receive(:new).with(user, author: user)
        .and_return(service)

      get :index
    end

    it_behaves_like 'snippets sort order'

    context 'when views are rendered' do
      render_views

      it 'avoids N+1 database queries' do
        # Warming call to load everything non snippet related
        get(:index)

        project = create(:project, namespace: user.namespace)
        create(:project_snippet, project: project, author: user)

        control_count = ActiveRecord::QueryRecorder.new { get(:index) }.count

        project = create(:project, namespace: user.namespace)
        create(:project_snippet, project: project, author: user)

        expect { get(:index) }.not_to exceed_query_limit(control_count)
      end
    end
  end
end
