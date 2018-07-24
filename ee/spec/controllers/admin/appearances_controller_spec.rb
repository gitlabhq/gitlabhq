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

    context 'when system messages feature is available' do
      it 'creates appearance with footer and header message' do
        stub_licensed_features(system_header_footer: true)

        post :create, appearance: create_params

        expect(Appearance.current).to have_attributes(
          header_message: header_message,
          footer_message: footer_message
        )
      end
    end

    context 'when system messages feature is not available' do
      it 'does not create appearance with footer and header message' do
        stub_licensed_features(system_header_footer: false)

        post :create, appearance: create_params

        expect(Appearance.current).to have_attributes(
          header_message: nil,
          footer_message: nil
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

    context 'when system messages feature is available' do
      it 'updates appearance with footer and header message' do
        stub_licensed_features(system_header_footer: true)

        put :update, appearance: update_params

        expect(Appearance.current).to have_attributes(
          header_message: header_message,
          footer_message: footer_message
        )
      end
    end

    context 'when system messages feature is not available' do
      it 'does not update appearance with footer and header message' do
        stub_licensed_features(system_header_footer: false)

        post :create, appearance: update_params

        expect(Appearance.current).to have_attributes(
          header_message: nil,
          footer_message: nil
        )
      end
    end
  end
end
