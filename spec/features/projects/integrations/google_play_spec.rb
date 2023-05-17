# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload Dropzone Field', feature_category: :integrations do
  include_context 'project integration activation'

  it 'uploads the file data to the correct form fields and updates the messaging correctly', :js, :aggregate_failures do
    visit_project_integration('Google Play')

    expect(page).to have_content('Drag your key file here or click to upload.')
    expect(page).not_to have_content('service_account.json')

    find("input[name='service[dropzone_file_name]']",
      visible: false).set(Rails.root.join('spec/fixtures/service_account.json'))

    expect(page).to have_field("service[service_account_key]", type: :hidden,
      with: File.read(Rails.root.join('spec/fixtures/service_account.json')))
    expect(page).to have_field("service[service_account_key_file_name]", type: :hidden, with: 'service_account.json')

    expect(page).not_to have_content('Drag your key file here or click to upload.')
    expect(page).to have_content('service_account.json')
  end
end
