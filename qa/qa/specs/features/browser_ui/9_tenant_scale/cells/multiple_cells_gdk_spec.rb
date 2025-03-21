# frozen_string_literal: true

# version of the login test that only runs against GDK

module QA
  RSpec.describe 'Tenant Scale', :skip_live_env, :requires_admin, product_group: :cells_infrastructure do
    describe 'Multiple Cells' do
      it(
        'user logged into one Cell is logged into all',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/433548',
        only: :local
      ) do
        Flow::Login.sign_in(as: create(:user))

        page.visit ENV.fetch('CELL2_URL')

        Page::Main::Menu.perform do |form|
          expect(form).to be_signed_in
        end
      end
    end
  end
end
