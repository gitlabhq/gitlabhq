# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores' do
    describe 'Subgroup transfer', product_group: :tenant_scale do
      let(:source_group) { create(:group, path: "source-group-for-transfer_#{SecureRandom.hex(8)}") }

      let!(:target_group) { create(:group, path: "target-group-for-transfer_#{SecureRandom.hex(8)}") }

      let(:sub_group_for_transfer) do
        create(:group, path: "subgroup-for-transfer_#{SecureRandom.hex(8)}", sandbox: source_group)
      end

      before do
        Flow::Login.sign_in
        sub_group_for_transfer.visit!
      end

      it 'transfers a subgroup to another group',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/471699',
          type: :investigating
        },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347692' do
        Page::Group::Menu.perform(&:go_to_general_settings)
        Page::Group::Settings::General.perform do |general|
          general.transfer_group(sub_group_for_transfer, target_group)

          sub_group_for_transfer.sandbox = target_group
          sub_group_for_transfer.reload!
        end

        expect(page).to have_text("Group '#{sub_group_for_transfer.path}' was successfully transferred.")
        expect(page.driver.current_url).to include(sub_group_for_transfer.full_path)
      end
    end
  end
end
