require 'spec_helper'

describe 'Help Pages', feature: true do
  describe 'Show SSH page' do
    before do
      login_as :user
    end
    it 'replaces the variable $your_email with the email of the user' do
      visit help_page_path('ssh/README')
      expect(page).to have_content("ssh-keygen -t rsa -C \"#{@user.email}\"")
    end
  end

  describe 'Get the main help page' do
    shared_examples_for 'help page' do
      it 'prefixes links correctly' do
        expect(page).to have_selector('div.documentation-index > ul a[href="/help/api/README.md"]')
      end
    end

    context 'without a trailing slash' do
      before do
        visit help_path
      end

      it_behaves_like 'help page'
    end

    context 'with a trailing slash' do
      before do
        visit help_path + '/'
      end

      it_behaves_like 'help page'
    end
  end
end
