require 'spec_helper'

describe Groups::UploadsController do
  let(:model) { create(:group, :public) }
  let(:params) do
    { group_id: model }
  end

  it_behaves_like 'handle uploads' do
    let(:uploader_class) { NamespaceFileUploader }
  end
end
