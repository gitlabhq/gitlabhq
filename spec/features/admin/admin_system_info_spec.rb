require 'spec_helper'

describe 'Admin System Info' do
  before do
    login_as :admin
  end

  describe 'GET /admin/system_info' do
    it 'shows system info page' do
      visit admin_system_info_path

      expect(page).to have_content 'CPU'
      expect(page).to have_content 'Memory'
      expect(page).to have_content 'Disks'
    end
  end
end
