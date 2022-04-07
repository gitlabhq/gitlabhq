# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Group Runners" do
  let_it_be(:group_owner) { create(:user) }
  let_it_be(:group) { create(:group) }

  let!(:group_registration_token) { group.runners_token }

  before do
    group.add_owner(group_owner)
    sign_in(group_owner)
  end

  describe "Group runners page", :js do
    describe "runners registration" do
      before do
        visit group_runners_path(group)
      end

      it_behaves_like "shows and resets runner registration token" do
        let(:dropdown_text) { 'Register a group runner' }
        let(:registration_token) { group_registration_token }
      end
    end
  end
end
