# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Gitlab::Experiment", :js do
  # This is part of a set of tests that ensure that tracking remains
  # consistent at the front end layer. Since we don't want to actually
  # introduce an experiment in real code, we're going to simulate it
  # here.
  let(:user) { create(:user) }

  before do
    admin = create(:admin)
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
    stub_experiments(null_hypothesis: :candidate)
  end

  describe 'with event tracking' do
    it 'publishes the experiments that have been run to the client', :experiment do
      allow_next_instance_of(Admin::AbuseReportsController) do |instance|
        allow(instance).to receive(:index).and_wrap_original do |original|
          instance.experiment(:null_hypothesis, user: instance.current_user) do |e|
            e.use { original.call }
            e.try { original.call }
          end
        end
      end

      visit admin_abuse_reports_path

      expect(page).to have_content('Abuse Reports')

      published_experiments = page.evaluate_script('window.gon.experiment')
      expect(published_experiments).to include({
        'null_hypothesis' => {
          'experiment' => 'null_hypothesis',
          'key' => anything,
          'variant' => 'candidate'
        }
      })
    end
  end
end
