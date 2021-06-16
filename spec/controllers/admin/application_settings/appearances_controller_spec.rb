# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ApplicationSettings::AppearancesController do
  let(:admin) { create(:admin) }
  let(:header_message) { 'Header message' }
  let(:footer_message) { 'Footer' }

  describe 'POST #create' do
    let(:create_params) do
      {
        title: 'Foo',
        description: 'Bar',
        header_message: header_message,
        footer_message: footer_message
      }
    end

    before do
      sign_in(admin)
    end

    it 'creates appearance with footer and header message' do
      post :create, params: { appearance: create_params }

      expect(Appearance.current).to have_attributes(
        header_message: header_message,
        footer_message: footer_message,
        email_header_and_footer_enabled: false,
        message_background_color: '#E75E40',
        message_font_color: '#FFFFFF'
      )
    end

    context 'when enabling header and footer in email' do
      it 'creates appearance with enabled flag' do
        create_params[:email_header_and_footer_enabled] = true

        post :create, params: { appearance: create_params }

        expect(Appearance.current).to have_attributes(
          header_message: header_message,
          footer_message: footer_message,
          email_header_and_footer_enabled: true
        )
      end
    end
  end

  describe 'PUT #update' do
    let(:update_params) do
      {
        header_message: header_message,
        footer_message: footer_message
      }
    end

    before do
      create(:appearance)

      sign_in(admin)
    end

    it 'updates appearance with footer and header message' do
      put :update, params: { appearance: update_params }

      expect(Appearance.current).to have_attributes(
        header_message: header_message,
        footer_message: footer_message,
        email_header_and_footer_enabled: false,
        message_background_color: '#E75E40',
        message_font_color: '#FFFFFF'
      )
    end

    context 'when enabling header and footer in email' do
      it 'updates appearance with enabled flag' do
        update_params[:email_header_and_footer_enabled] = true

        post :update, params: { appearance: update_params }

        expect(Appearance.current).to have_attributes(
          header_message: header_message,
          footer_message: footer_message,
          email_header_and_footer_enabled: true
        )
      end
    end
  end
end
