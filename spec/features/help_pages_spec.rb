require 'spec_helper'

describe 'Help Pages', feature: true do
  describe 'Get the main help page' do
    shared_examples_for 'help page' do |prefix: ''|
      it 'prefixes links correctly' do
        expect(page).to have_selector(%(div.documentation-index > ul a[href="#{prefix}/help/api/README.md"]))
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

    context 'with a relative installation' do
      before do
        stub_config_setting(relative_url_root: '/gitlab')
        visit help_path
      end

      it_behaves_like 'help page', prefix: '/gitlab'
    end
  end
end
