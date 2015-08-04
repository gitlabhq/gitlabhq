require 'spec_helper'

feature 'Group', feature: true do
  describe 'description' do
    let(:group) { create(:group) }
    let(:path)  { group_path(group) }

    before do
      login_as(:admin)
    end

    it 'parses Markdown' do
      group.update_attribute(:description, 'This is **my** group')
      visit path
      expect(page).to have_css('.description > p > strong')
    end

    it 'passes through html-pipeline' do
      group.update_attribute(:description, 'This group is the :poop:')
      visit path
      expect(page).to have_css('.description > p > img')
    end

    it 'sanitizes unwanted tags' do
      group.update_attribute(:description, '# Group Description')
      visit path
      expect(page).not_to have_css('.description h1')
    end

    it 'permits `rel` attribute on links' do
      group.update_attribute(:description, 'https://google.com/')
      visit path
      expect(page).to have_css('.description a[rel]')
    end
  end
end
