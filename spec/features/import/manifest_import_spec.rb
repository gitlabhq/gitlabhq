# frozen_string_literal: true

require 'spec_helper'

describe 'Import multiple repositories by uploading a manifest file', :js do
  include Select2Helper

  let(:user) { create(:admin) }
  let(:group) { create(:group) }

  before do
    sign_in(user)

    group.add_owner(user)
  end

  it 'parses manifest file and list repositories' do
    visit new_import_manifest_path

    attach_file('manifest', Rails.root.join('spec/fixtures/aosp_manifest.xml'))
    click_on 'List available repositories'

    expect(page).to have_button('Import all repositories')
    expect(page).to have_content('https://android-review.googlesource.com/platform/build/blueprint')
  end

  it 'imports successfully imports a project', :sidekiq_inline do
    visit new_import_manifest_path

    attach_file('manifest', Rails.root.join('spec/fixtures/aosp_manifest.xml'))
    click_on 'List available repositories'

    page.within(second_row) do
      click_on 'Import'

      expect(page).to have_content 'Done'
      expect(page).to have_content("#{group.full_path}/build/blueprint")
    end
  end

  it 'renders an error if invalid file was provided' do
    visit new_import_manifest_path

    attach_file('manifest', Rails.root.join('spec/fixtures/banana_sample.gif'))
    click_on 'List available repositories'

    expect(page).to have_content 'The uploaded file is not a valid XML file.'
  end

  def second_row
    page.all('table.import-jobs tbody tr')[1]
  end
end
