class Spinach::Features::AdminLicense < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  step 'I should see to whom the license is licensed' do
    expect(page).to have_content(license.licensee.values.first)
  end

  step 'there is a license' do
    create(:license)
  end

  step 'there is no license' do
    License.destroy_all
  end

  step 'I should be redirected to the license upload page' do
    expect(current_path).to eq(new_admin_license_path)
  end

  step 'the current license is expired' do
    build(:license, data: build(:gitlab_license, expires_at: Date.yesterday).export).save(validate: false)
  end

  step 'I should see a warning telling me the license has expired' do
    expect(page).to have_content "Your license expired"
  end

  step 'the current license blocks changes' do
    build(:license, data: build(:gitlab_license, expires_at: Date.yesterday, block_changes_at: Date.today).export).save(validate: false)
  end

  step 'I should see a warning telling me code pushes have been disabled' do
    expect(page).to have_content "Pushing code and creation of issues and merge requests has been disabled."
  end

  step 'there are multiple licenses' do
    create(:license)
    create(:license)
  end

  step 'I should see to whom the licenses were licensed' do
    license_history = page.find("#license_history")

    License.previous.each do |license|
      expect(license_history).to have_content(license.licensee.values.first)
    end
  end

  step 'I visit admin upload license page' do
    visit new_admin_license_path
  end

  step 'I upload a valid license' do
    path = Rails.root.join("tmp/valid_license.gitlab-license")

    license = build(:gitlab_license)
    File.write(path, license.export)

    attach_file 'license_data_file', path
    click_button "Upload license"
  end

  step 'I should see a notice telling me the license was uploaded' do
    expect(page).to have_content "The license was successfully uploaded and is now active."
  end

  step 'I upload an invalid license' do
    path = Rails.root.join("tmp/invalid_license.gitlab-license")

    license = build(:gitlab_license, expires_at: Date.yesterday)
    File.write(path, license.export)

    attach_file 'license_data_file', path
    click_button "Upload license"
  end

  step "I should see a warning telling me it's invalid" do
    expect(page).to have_content "This license has already expired."
  end

  def license
    License.reset_current
    License.current
  end
end
