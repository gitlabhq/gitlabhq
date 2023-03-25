# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload Dropzone Field', feature_category: :integrations do
  include_context 'project integration activation'

  it 'uploads the file data to the correct form fields and updates the messaging correctly', :js, :aggregate_failures do
    visit_project_integration('Apple App Store Connect')

    expect(page).to have_content('Drag your Private Key file here or click to upload.')
    expect(page).not_to have_content('auth_key.p8')

    find("input[name='service[dropzone_file_name]']",
      visible: false).set(Rails.root.join('spec/fixtures/auth_key.p8'))

    expect(page).to have_field("service[app_store_private_key]", type: :hidden,
      with: File.read(Rails.root.join('spec/fixtures/auth_key.p8')))
    expect(page).to have_field("service[app_store_private_key_file_name]", type: :hidden, with: 'auth_key.p8')

    expect(page).not_to have_content('Drag your Private Key file here or click to upload.')
    expect(page).to have_content('auth_key.p8')
  end
end
