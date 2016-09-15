require 'rails_helper'

describe 'Profile > SSH Keys', feature: true do
  let(:user) { create(:user) }

  before do
    login_as(user)
    visit profile_keys_path
  end

  describe 'User adds an SSH key' do
    it 'auto-populates the title', js: true do
      fill_in('Key', with: attributes_for(:key).fetch(:key))

      expect(find_field('Title').value).to eq 'dummy@gitlab.com'
    end
  end
end
