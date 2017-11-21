require 'spec_helper'

describe Groups::UploadsController do
  let(:model) { create(:group) }
  let(:params) do
    { group_id: model }
  end

  it_behaves_like 'handle uploads'
end
