# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :smoke, :health_check, :mobile, product_group: :authentication do
    describe 'basic user login' do
      it 'user logs in using basic credentials and logs out',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347880' do
        Flow::Login.sign_in

        Page::Main::Menu.perform do |menu|
          expect(menu).to have_personal_area
        end

        Support::Retrier.retry_until(sleep_interval: 0.5) do
          Page::Main::Menu.perform(&:sign_out)

          Page::Main::Login.perform(&:can_sign_in?)
        end

        Page::Main::Login.perform do |form|
          expect(form.can_sign_in?).to be(true)
        end
      end
    end
  end
end
