require 'rails_helper'

describe 'Display system header and footer bar' do
  let(:header_message) { "Foo" }
  let(:footer_message) { "Bar" }

  shared_examples 'system header is configured' do
    it 'shows system header' do
      expect(page).to have_css('.header-message')
    end

    it 'shows the correct content' do
      page.within('.header-message') do
        expect(page).to have_content(header_message)
      end
    end
  end

  shared_examples 'system footer is configured' do
    it 'shows system footer' do
      expect(page).to have_css('.footer-message')
    end

    it 'shows the correct content' do
      page.within('.footer-message') do
        expect(page).to have_content(footer_message)
      end
    end
  end

  shared_examples 'system header is not configured' do
    it 'does not show system header' do
      expect(page).not_to have_css('.header-message')
    end
  end

  shared_examples 'system footer is not configured' do
    it 'does not show system footer' do
      expect(page).not_to have_css('.footer-message')
    end
  end

  context 'when authenticated' do
    context 'when system header and footer are not configured' do
      before do
        sign_in(create(:user))

        visit root_path
      end

      it_behaves_like 'system header is not configured'
      it_behaves_like 'system footer is not configured'
    end

    context 'when only system header is defined' do
      before do
        create(:appearance, header_message: header_message)

        sign_in(create(:user))
        visit root_path
      end

      it_behaves_like 'system header is configured'
      it_behaves_like 'system footer is not configured'
    end

    context 'when only system footer is defined' do
      before do
        create(:appearance, footer_message: footer_message)

        sign_in(create(:user))
        visit root_path
      end

      it_behaves_like 'system header is not configured'
      it_behaves_like 'system footer is configured'
    end

    context 'when system header and footer are defined' do
      before do
        create(:appearance, header_message: header_message, footer_message: footer_message)

        sign_in(create(:user))
        visit root_path
      end

      it_behaves_like 'system header is configured'
      it_behaves_like 'system footer is configured'
    end
  end

  context 'when not authenticated' do
    context 'when system header and footer are not configured' do
      before do
        visit root_path
      end

      it_behaves_like 'system header is not configured'
      it_behaves_like 'system footer is not configured'
    end

    context 'when only system header is defined' do
      before do
        create(:appearance, header_message: header_message)

        visit root_path
      end

      it_behaves_like 'system header is configured'
      it_behaves_like 'system footer is not configured'
    end

    context 'when only system footer is defined' do
      before do
        create(:appearance, footer_message: footer_message)

        visit root_path
      end

      it_behaves_like 'system header is not configured'
      it_behaves_like 'system footer is configured'
    end

    context 'when system header and footer are defined' do
      before do
        create(:appearance, header_message: header_message, footer_message: footer_message)

        visit root_path
      end

      it_behaves_like 'system header is configured'
      it_behaves_like 'system footer is configured'
    end
  end
end
