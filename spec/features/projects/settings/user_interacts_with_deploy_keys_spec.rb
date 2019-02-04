require "spec_helper"

describe "User interacts with deploy keys", :js do
  let(:project) { create(:project, :repository) }
  let(:user) { project.owner }

  before do
    sign_in(user)
  end

  shared_examples "attaches a key" do
    it "attaches key" do
      visit(project_deploy_keys_path(project))

      page.within(".deploy-keys") do
        find(".badge", text: "1").click

        click_button("Enable")

        expect(page).not_to have_selector(".fa-spinner")
        expect(current_path).to eq(project_settings_repository_path(project))

        find(".js-deployKeys-tab-enabled_keys").click

        expect(page).to have_content(deploy_key.title)
      end
    end
  end

  context "viewing deploy keys" do
    let(:deploy_key) { create(:deploy_key) }

    context "when project has keys" do
      before do
        create(:deploy_keys_project, project: project, deploy_key: deploy_key)
      end

      it "shows deploy keys" do
        visit(project_deploy_keys_path(project))

        page.within(".deploy-keys") do
          expect(page).to have_content(deploy_key.title)
        end
      end
    end

    context "when another project has keys" do
      let(:another_project) { create(:project) }

      before do
        create(:deploy_keys_project, project: another_project, deploy_key: deploy_key)

        another_project.add_maintainer(user)
      end

      it "shows deploy keys" do
        visit(project_deploy_keys_path(project))

        page.within(".deploy-keys") do
          find('.js-deployKeys-tab-available_project_keys').click

          expect(page).to have_content(deploy_key.title)
          expect(find(".js-deployKeys-tab-available_project_keys .badge")).to have_content("1")
        end
      end
    end

    context "when there are public deploy keys" do
      let!(:deploy_key) { create(:deploy_key, public: true) }

      it "shows public deploy keys" do
        visit(project_deploy_keys_path(project))

        page.within(".deploy-keys") do
          find(".js-deployKeys-tab-public_keys").click

          expect(page).to have_content(deploy_key.title)
        end
      end
    end
  end

  context "adding deploy keys" do
    before do
      visit(project_deploy_keys_path(project))
    end

    it "adds new key" do
      DEPLOY_KEY_TITLE = attributes_for(:key)[:title]
      DEPLOY_KEY_BODY  = attributes_for(:key)[:key]

      fill_in("deploy_key_title", with: DEPLOY_KEY_TITLE)
      fill_in("deploy_key_key",   with: DEPLOY_KEY_BODY)

      click_button("Add key")

      expect(current_path).to eq(project_settings_repository_path(project))

      page.within(".deploy-keys") do
        expect(page).to have_content(DEPLOY_KEY_TITLE)
      end
    end
  end

  context "attaching existing keys" do
    context "from another project" do
      let(:another_project) { create(:project) }
      let(:deploy_key) { create(:deploy_key) }

      before do
        create(:deploy_keys_project, project: another_project, deploy_key: deploy_key)

        another_project.add_maintainer(user)
      end

      it_behaves_like "attaches a key"
    end

    context "when keys are public" do
      let!(:deploy_key) { create(:deploy_key, public: true) }

      it_behaves_like "attaches a key"
    end
  end
end
