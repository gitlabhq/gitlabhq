# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GracefulTimeoutHandling, type: :controller do
  controller(ApplicationController) do
    include GracefulTimeoutHandling

    skip_before_action :authenticate_user!

    def index
      raise ActiveRecord::QueryCanceled
    end
  end

  context 'for json request' do
    subject { get :index, format: :json }

    it 'renders graceful error message' do
      subject

      expect(json_response['error']).to eq(_('There is too much data to calculate. Please change your selection.'))
      expect(response.code).to eq '200'
    end

    it 'logs exception' do
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(kind_of(ActiveRecord::QueryCanceled))

      subject
    end
  end

  context 'for html request' do
    subject { get :index, format: :html }

    it 'has no effect' do
      expect do
        subject
      end.to raise_error(ActiveRecord::QueryCanceled)
    end
  end
end
