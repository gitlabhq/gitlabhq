require 'spec_helper'

describe Admin::AppearancesController do
  let(:admin) { create(:admin) }
  let(:header_message) { "Header message" }
  let(:footer_message) { "Footer" }

  describe 'POST #create' do
    let(:create_params) do
      {
        title: "Foo",
        description: "Bar",
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
        footer_message: footer_message
      )
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
        footer_message: footer_message
      )
    end
  end
end
