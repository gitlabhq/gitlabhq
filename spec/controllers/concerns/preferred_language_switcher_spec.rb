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

  context 'when first visit' do
    before do
      get :new
    end

    it 'sets preferred_language to default' do
      expect(cookies[:preferred_language]).to eq Gitlab::CurrentSettings.default_preferred_language
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
        expect(cookies[:preferred_language]).to eq user_preferred_language
      end
    end

    context 'with an invalid value' do
      let(:user_preferred_language) { 'xxx' }

      it 'sets preferred_language to default' do
        expect(cookies[:preferred_language]).to eq Gitlab::CurrentSettings.default_preferred_language
      end
    end
  end
end
