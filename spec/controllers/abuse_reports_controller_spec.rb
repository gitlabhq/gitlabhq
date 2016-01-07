require 'spec_helper'

describe AbuseReportsController do
  let(:reporter) { create(:user) }
  let(:user)     { create(:user) }
  let(:attrs) do
    attributes_for(:abuse_report) do |hash|
      hash[:user_id] = user.id
    end
  end

  before do
    sign_in(reporter)
  end

  describe 'POST create' do
    context 'with valid attributes' do
      it 'saves the abuse report' do
        expect do
          post :create, abuse_report: attrs
        end.to change { AbuseReport.count }.by(1)
      end

      it 'calls notify' do
        expect_any_instance_of(AbuseReport).to receive(:notify)

        post :create, abuse_report: attrs
      end

      it 'redirects back to the reported user' do
        post :create, abuse_report: attrs

        expect(response).to redirect_to user
      end
    end

    context 'with invalid attributes' do
      it 'renders new' do
        attrs.delete(:user_id)
        post :create, abuse_report: attrs

        expect(response).to render_template(:new)
      end
    end
  end
end
