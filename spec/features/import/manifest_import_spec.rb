require 'spec_helper'

feature 'Import multiple repositories by uploading a manifest file' do
  include Select2Helper

  let(:user) { create(:admin) }
  let(:group) { create(:group) }

  before do
    sign_in(user)

    group.add_owner(user)
  end

  it 'parses manifest file and list repositories', :js do
    visit new_import_manifest_path

    attach_file('manifest', Rails.root.join('spec/fixtures/aosp_manifest.xml'))
    click_on 'Continue to the next step'

    expect(page).to have_button('Import all repositories')
    expect(page).to have_content('https://android-review.googlesource.com/platform/build/blueprint')
  end
end
