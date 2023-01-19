# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AppearancesHelper do
  let_it_be(:gitlab_logo) { ActionController::Base.helpers.image_path('logo.svg') }

  before do
    user = create(:user)
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#appearance_pwa_name' do
    it 'returns the default value' do
      create(:appearance)

      expect(helper.appearance_pwa_name).to match('GitLab')
    end

    it 'returns the customized value' do
      create(:appearance, pwa_name: 'GitLab as PWA')

      expect(helper.appearance_pwa_name).to match('GitLab as PWA')
    end
  end

  describe '#appearance_pwa_short_name' do
    it 'returns the default value' do
      create(:appearance)

      expect(helper.appearance_pwa_short_name).to match('GitLab')
    end

    it 'returns the customized value' do
      create(:appearance, pwa_short_name: 'Short')

      expect(helper.appearance_pwa_short_name).to match('Short')
    end
  end

  describe '#appearance_pwa_description' do
    it 'returns the default value' do
      create(:appearance)

      expect(helper.appearance_pwa_description).to include('The complete DevOps platform.')
    end

    it 'returns the customized value' do
      create(:appearance, pwa_description: 'This is a description')

      expect(helper.appearance_pwa_description).to match('This is a description')
    end
  end

  describe '.current_appearance' do
    it 'memoizes empty appearance' do
      expect(Appearance).to receive(:current).once

      2.times { helper.current_appearance }
    end

    it 'memoizes custom appearance' do
      create(:appearance)

      expect(Appearance).to receive(:current).once.and_call_original

      2.times { helper.current_appearance }
    end
  end

  describe '#header_message' do
    it 'returns nil when header message field is not set' do
      create(:appearance)

      expect(helper.header_message).to be_nil
    end

    context 'when header message is set' do
      it 'includes current message' do
        message = "Foo bar"
        create(:appearance, header_message: message)

        expect(helper.header_message).to include(message)
      end
    end
  end

  describe '#footer_message' do
    it 'returns nil when footer message field is not set' do
      create(:appearance)

      expect(helper.footer_message).to be_nil
    end

    context 'when footer message is set' do
      it 'includes current message' do
        message = "Foo bar"
        create(:appearance, footer_message: message)

        expect(helper.footer_message).to include(message)
      end
    end
  end

  describe '#brand_image' do
    context 'when there is a logo' do
      let!(:appearance) { create(:appearance, :with_logo) }

      it 'returns a path' do
        expect(helper.brand_image).to match(%r(img .* data-src="/uploads/-/system/appearance/.*png))
      end

      context 'when there is no associated upload' do
        before do
          # Legacy attachments were not tracked in the uploads table
          appearance.logo.upload.destroy!
          appearance.reload
        end

        it 'falls back to using the original path' do
          expect(helper.brand_image).to match(%r(img .* data-src="/uploads/-/system/appearance/.*png))
        end
      end
    end

    context 'when there is no logo' do
      it 'returns path of GitLab logo' do
        expect(helper.brand_image).to match(%r(img .* data-src="#{gitlab_logo}))
      end
    end

    context 'when there is a title' do
      let!(:appearance) { create(:appearance, title: 'My title') }

      it 'returns the title' do
        expect(helper.brand_image).to match(%r(img alt="My title"))
      end
    end

    context 'when there is no title' do
      it 'returns the default title' do
        expect(helper.brand_image).to match(%r(img alt="GitLab))
      end
    end
  end

  describe '#brand_image_path' do
    context 'with a custom logo' do
      let!(:appearance) { create(:appearance, :with_logo) }

      it 'returns path of custom logo' do
        expect(helper.brand_image_path).to match(%r(/uploads/-/system/appearance/.*/dk.png))
      end
    end

    context 'with no custom logo' do
      it 'returns path of GitLab logo' do
        expect(helper.brand_image_path).to eq(gitlab_logo)
      end
    end
  end

  describe '#brand_header_logo' do
    let(:options) { {} }

    subject do
      helper.brand_header_logo(options)
    end

    context 'with header logo' do
      let!(:appearance) { create(:appearance, :with_header_logo) }

      it 'renders image tag' do
        expect(helper).to receive(:image_tag).with(appearance.header_logo_path, class: 'brand-header-logo')

        subject
      end
    end

    context 'with add_gitlab_white_text option' do
      let(:options) { { add_gitlab_white_text: true } }

      it 'renders shared/logo_with_white_text partial' do
        expect(helper).to receive(:render).with(partial: 'shared/logo_with_white_text', formats: :svg)

        subject
      end
    end

    context 'with add_gitlab_black_text option' do
      let(:options) { { add_gitlab_black_text: true } }

      it 'renders shared/logo_with_black_text partial' do
        expect(helper).to receive(:render).with(partial: 'shared/logo_with_black_text', formats: :svg)

        subject
      end
    end

    it 'renders shared/logo by default' do
      expect(helper).to receive(:render).with(partial: 'shared/logo', formats: :svg)

      subject
    end
  end

  describe '#brand_title' do
    it 'returns the default title when no appearance is present' do
      allow(helper).to receive(:current_appearance).and_return(nil)

      expect(helper.brand_title).to eq(helper.default_brand_title)
    end
  end

  describe '#default_brand_title' do
    it 'returns the default title' do
      edition = Gitlab.ee? ? 'Enterprise' : 'Community'
      expected_default_brand_title = "GitLab #{edition} Edition"

      expect(helper.default_brand_title).to eq _(expected_default_brand_title)
    end
  end
end
