# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Root explore', feature_category: :not_owned do
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:archived_project) { create(:project, :archived) }
  let_it_be(:internal_project) { create(:project, :internal) }
  let_it_be(:private_project) { create(:project, :private) }

  before do
    allow(Gitlab).to receive(:com?).and_return(true)
  end

  context 'when logged in' do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
      visit explore_projects_path
    end

    include_examples 'shows public and internal projects'
  end

  context 'when not logged in' do
    before do
      visit explore_projects_path
    end

    include_examples 'shows public projects'
  end

  describe 'project language dropdown' do
    using RSpec::Parameterized::TableSyntax

    where(:project_language_search, :project_list_filter_bar, :render_project_language_dropdown) do
      false | false | false
      false | true  | false
      true  | false | true
      true  | true  | false
    end

    with_them do
      before do
        stub_feature_flags(project_language_search: project_language_search)
        stub_feature_flags(project_list_filter_bar: project_list_filter_bar)
      end

      let(:has_language_dropdown?) { page.has_selector?('[data-testid="project-language-dropdown"]') }

      it 'is conditionally rendered' do
        visit explore_projects_path

        expect(has_language_dropdown?).to eq(render_project_language_dropdown)
      end
    end
  end
end
