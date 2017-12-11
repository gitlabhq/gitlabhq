require 'spec_helper'

describe Dashboard::TodosController do
  before do
    sign_in create(:user)
  end

  describe '#index' do
    subject { get :index }

    it_behaves_like 'disabled when using an external authorization service'
  end
end
