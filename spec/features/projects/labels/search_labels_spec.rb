require 'spec_helper'

describe 'Search for labels', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let!(:label1) { create(:label, title: 'Foo', description: 'Lorem ipsum', project: project) }
  let!(:label2) { create(:label, title: 'Bar', description: 'Fusce consequat', project: project) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it 'searches for label by title' do
    visit project_labels_path(project)

    fill_in 'label-search', with: 'Bar'
    find('#label-search').native.send_keys(:enter)

    expect(page).to have_content(label2.title)
    expect(page).to have_content(label2.description)
    expect(page).not_to have_content(label1.title)
    expect(page).not_to have_content(label1.description)
  end

  it 'searches for label by title' do
    visit project_labels_path(project)

    fill_in 'label-search', with: 'Lorem'
    find('#label-search').native.send_keys(:enter)

    expect(page).to have_content(label1.title)
    expect(page).to have_content(label1.description)
    expect(page).not_to have_content(label2.title)
    expect(page).not_to have_content(label2.description)
  end
end
