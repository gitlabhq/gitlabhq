# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User tags a project' do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }

  before do
    sign_in(user)
    visit edit_project_path(project)
  end

  it 'sets project topics' do
    fill_in 'Topics', with: 'topic1, topic2'

    page.within '.general-settings' do
      click_button 'Save changes'
    end

    expect(find_field('Topics').value).to eq 'topic1, topic2'
  end
end
