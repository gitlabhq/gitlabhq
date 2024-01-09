# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores', :skip_live_env, :requires_admin, product_group: :tenant_scale do
    describe 'Multiple Cells' do
      let(:url) { 'gitlab-cells.bridge' }

      let(:cells) { Service::Gitlab::Instances.new }
      let!(:first_cell) do
        cells.add_gitlab_instance(name: 'gitlab-first-cell',
          external_port: '3000',
          url: url)
      end

      let!(:second_cell) do
        cells.add_gitlab_instance(name: 'gitlab-second-cell',
          external_port: '3001',
          url: url)
      end

      before do
        cells.set_gitlab_urls(first_cell)

        cells.wait_for_all_instances

        # TODO: configure cells to be connected

        page.visit first_cell.external_url
      end

      after do
        cells.remove_all_instances
      end

      it(
        'user logged into one Cell is logged into all',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/433542',
        only: :local
      ) do
        Flow::Login.sign_in(as: create(:user))

        page.visit second_cell.external_url

        Page::Main::Menu.perform do |form|
          expect(form).to be_signed_in
        end
      end
    end
  end
end
