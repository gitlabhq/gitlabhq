require 'spec_helper'

describe 'Admin Global Labels' do
  before do
    login_as :admin
  end

  describe 'Listing labels' do
    context 'when have labels' do
      it 'shows all labels' do
        create(:global_label, title: 'bug')
        create(:global_label, title: 'feature')
        create(:global_label, title: 'enhancement')

        visit admin_labels_path

        page.within('.global-labels') do
          expect(page.all('.label-row').size).to eq(3)
          expect(page).to have_content 'bug'
          expect(page).to have_content 'feature'
          expect(page).to have_content 'enhancement'
        end
      end
    end

    context 'when have no labels' do
      it 'shows a message' do
        visit admin_labels_path

        expect(page).to have_content 'There are no labels yet'
      end
    end
  end

  describe 'Creating labels' do
    context 'with valid attributes' do
      it 'creates a new label' do
        visit new_admin_label_path

        fill_in 'Title', with: 'support'
        fill_in 'Background color', with: '#F95610'

        click_button 'Save'

        page.within('.global-labels') do
          expect(page).to have_content 'support'
        end
      end
    end

    context 'with invalid color' do
      it 'shows an error message' do
        visit new_admin_label_path

        fill_in 'Title', with: 'support'
        fill_in 'Background color', with: '#12'

        click_button 'Save'

        expect(page).to have_content 'Color must be a valid color code'
      end
    end

    context 'with title that already exists' do
      it 'shows an error message' do
        create(:global_label, title: 'bug')

        visit new_admin_label_path

        fill_in 'Title', with: 'bug'
        fill_in 'Background color', with: '#F95610'

        click_button 'Save'

        expect(page).to have_content 'Title has already been taken'
      end
    end
  end

  describe 'Editing labels' do
    context 'with valid attributes' do
      it 'updates the label' do
        label = create(:global_label, title: 'bug')

        visit edit_admin_label_path(label)

        fill_in 'Title', with: 'fix'

        click_button 'Save'

        page.within('.global-labels') do
          expect(page).not_to have_content 'bug'
          expect(page).to have_content 'fix'
        end
      end
    end
  end

  describe 'Removing labels' do
    it 'removes the label from the list' do
      bug = create(:global_label, title: 'bug')
      create(:global_label, title: 'enhancement')

      visit admin_labels_path

      page.within("#label_#{bug.id} .pull-right") do
        click_link 'Delete'
      end

      page.within('.global-labels') do
        expect(page).not_to have_content 'bug'
        expect(page).to have_content 'enhancement'
      end
    end
  end
end
