require "spec_helper"

describe "Admin uploads license" do
  set(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  context "when license key is provided in the query string" do
    set(:license) { build(:license, data: build(:gitlab_license, restrictions: { active_user_count: 2000 }).export) }

    before do
      License.destroy_all

      visit(admin_license_path(trial_key: license.data))
    end

    it "installs license" do
      page.within("#modal-upload-trial-license") do
        expect(page).to have_content("Your trial license was issued").and have_button("Install license")
      end

      click_button("Install license")

      expect(page).to have_content("The license was successfully uploaded and is now active")
    end
  end

  context "uploading license" do
    before do
      visit(new_admin_license_path)

      File.write(path, license.export)
    end

    context "when license is valid" do
      set(:license) { build(:gitlab_license) }
      set(:path) { Rails.root.join("tmp/valid_license.gitlab-license") }

      it "uploads license" do
        attach_and_upload(path)

        expect(page).to have_content("The license was successfully uploaded and is now active.")
                   .and have_content(license.licensee.values.first)
      end
    end

    context "when license is invalid" do
      set(:license) { build(:gitlab_license, expires_at: Date.yesterday) }
      set(:path) { Rails.root.join("tmp/invalid_license.gitlab-license") }

      it "doesn't upload license" do
        attach_and_upload(path)

        expect(page).to have_content("This license has already expired.")
      end
    end
  end

  private

  def attach_and_upload(path)
    attach_file("license_data_file", path)
    click_button("Upload license")
  end
end
