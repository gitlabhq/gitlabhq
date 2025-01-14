# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreferredLanguageSwitcher, type: :controller, feature_category: :acquisition do
  controller(ActionController::Base) do
    include PreferredLanguageSwitcher

    before_action :init_preferred_language, only: :new

    def new
      render html: 'new page'
    end
  end

  subject { cookies[:preferred_language] }

  before do
    stub_feature_flags(disable_preferred_language_cookie: false)
  end

  context 'for first visit' do
    let(:accept_language_header) { nil }

    before do
      request.env['HTTP_ACCEPT_LANGUAGE'] = accept_language_header
      stub_const('PreferredLanguageSwitcherHelper::SWITCHER_MINIMUM_TRANSLATION_LEVEL', 50)

      get :new
    end

    it { is_expected.to eq Gitlab::CurrentSettings.default_preferred_language }

    context 'when browser preferred language is not english' do
      context 'with selectable language' do
        let(:accept_language_header) { 'zh-CN,zh;q=0.8,zh-TW;q=0.7' }

        it { is_expected.to eq 'zh_CN' }
      end

      context 'with unselectable language' do
        let(:accept_language_header) { 'nl-NL;q=0.8' }

        it { is_expected.to eq Gitlab::CurrentSettings.default_preferred_language }
      end

      context 'with empty string in language header' do
        let(:accept_language_header) { '' }

        it { is_expected.to eq Gitlab::CurrentSettings.default_preferred_language }
      end

      context 'with language header without dashes' do
        let(:accept_language_header) { 'fr;q=8' }

        it { is_expected.to eq 'fr' }
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

      it { is_expected.to eq user_preferred_language }
    end

    context 'with an invalid value' do
      let(:user_preferred_language) { 'xxx' }

      it { is_expected.to eq Gitlab::CurrentSettings.default_preferred_language }
    end
  end

  context 'with disable_preferred_language_cookie feature flag enabled' do
    before do
      stub_feature_flags(disable_preferred_language_cookie: true)
      get :new
    end

    it { is_expected.to be_nil }
  end
end
