require 'spec_helper'

describe Dashboard::LabelsController do
  before do
    sign_in create(:user)
  end

  describe '#index' do
    subject { get :index, format: :json }

    it_behaves_like 'disabled when using an external authorization service'
  end
end
