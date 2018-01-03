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

  describe 'GET new' do
    context 'when the user has already been deleted' do
      it 'redirects the reporter to root_path' do
        user_id = user.id
        user.destroy

        get :new, { user_id: user_id }

        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq('Cannot create the abuse report. The user has been deleted.')
      end
    end

    context 'when the user has already been blocked' do
      it 'redirects the reporter to the user\'s profile' do
        user.block

        get :new, { user_id: user.id }

        expect(response).to redirect_to user
        expect(flash[:alert]).to eq('Cannot create the abuse report. This user has been blocked.')
      end
    end
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
