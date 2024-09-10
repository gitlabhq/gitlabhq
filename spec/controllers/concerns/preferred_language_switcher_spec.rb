# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreferredLanguageSwitcher, type: :controller do
  controller(ActionController::Base) do
    include PreferredLanguageSwitcher # rubocop:disable RSpec/DescribedClass

    before_action :init_preferred_language, only: :new

    def new
      render html: 'new page'
    end
  end

  subject { cookies[:preferred_language] }

  before do
    stub_feature_flags(disable_preferred_language_cookie: false)
  end

  context 'when first visit' do
    let(:glm_source) { 'about.gitlab.com' }
    let(:accept_language_header) { nil }

    before do
      request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language_header

      get :new, params: { glm_source: glm_source }
    end

    it 'sets preferred_language to default' do
      expect(subject).to eq Gitlab::CurrentSettings.default_preferred_language
    end

    context 'when language param is valid' do
      let(:glm_source) { 'about.gitlab.com/fr-fr/' }

      it 'sets preferred_language accordingly' do
        expect(subject).to eq 'fr'
      end

      context 'for case insensitivity on language' do
        let(:glm_source) { 'about.gitlab.com/fr-FR/' }

        it 'sets preferred_language accordingly' do
          expect(subject).to eq 'fr'
        end
      end

      context 'for case insensitivity on marketing site URL' do
        let(:glm_source) { 'ABOUT.gitlab.com/fr-fr/' }

        it 'sets preferred_language accordingly' do
          expect(subject).to eq 'fr'
        end
      end

      context 'when language param is invalid' do
        let(:glm_source) { 'about.gitlab.com/ko-ko/' }

        it 'sets preferred_language to default' do
          expect(subject).to eq Gitlab::CurrentSettings.default_preferred_language
        end
      end

      context 'when the glm_source is not the marketing site' do
        let(:glm_source) { 'some.othersite.com/fr-fr/' }

        it 'sets preferred_language to default' do
          expect(subject).to eq Gitlab::CurrentSettings.default_preferred_language
        end
      end
    end

    context 'when browser preferred language is not english' do
      context 'with selectable language' do
        let(:accept_language_header) { 'zh-CN,zh;q=0.8,zh-TW;q=0.7' }

        it 'sets preferred_language accordingly' do
          expect(subject).to eq 'zh_CN'
        end
      end

      context 'with unselectable language' do
        let(:accept_language_header) { 'nl-NL;q=0.8' }

        it 'sets preferred_language to default' do
          expect(subject).to eq Gitlab::CurrentSettings.default_preferred_language
        end
      end

      context 'with empty string in language header' do
        let(:accept_language_header) { '' }

        it 'sets preferred_language to default' do
          expect(subject).to eq Gitlab::CurrentSettings.default_preferred_language
        end
      end

      context 'with language header without dashes' do
        let(:accept_language_header) { 'fr;q=8' }

        it 'sets preferred_language accordingly' do
          expect(subject).to eq 'fr'
        end
      end
    end

    context 'when language params and language header are both valid' do
      let(:accept_language_header) { 'zh-CN,zh;q=0.8,zh-TW;q=0.7' }
      let(:glm_source) { 'about.gitlab.com/fr-fr/' }

      it 'sets preferred_language according to language params' do
        expect(subject).to eq 'fr'
      end
    end
  end

  context 'when preferred language in cookies has been modified' do
    let(:user_preferred_language) { nil }

    before do
      cookies[:preferred_language] = user_preferred_language

      get :new
    end

    context 'with a valid value' do
      let(:user_preferred_language) { 'zh_CN' }

      it 'keeps preferred language unchanged' do
        expect(subject).to eq user_preferred_language
      end
    end

    context 'with an invalid value' do
      let(:user_preferred_language) { 'xxx' }

      it 'sets preferred_language to default' do
        expect(subject).to eq Gitlab::CurrentSettings.default_preferred_language
      end
    end
  end

  context 'with disable_preferred_language_cookie feature flag enabled' do
    before do
      stub_feature_flags(disable_preferred_language_cookie: true)
      get :new
    end

    it 'does not set the cookie' do
      expect(subject).to be_nil
    end
  end
end
