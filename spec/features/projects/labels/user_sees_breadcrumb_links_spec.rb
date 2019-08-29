# frozen_string_literal: true

require 'spec_helper'

describe 'New project label breadcrumb' do
  let(:project) { create(:project) }
  let(:user) { project.creator }

  before do
    sign_in(user)
    visit(project_labels_path(project))
  end

  it 'displays link to project labels and new project label' do
    page.within '.breadcrumbs' do
      expect(find_link('Labels')[:href]).to end_with(project_labels_path(project))
    end
  end
end
