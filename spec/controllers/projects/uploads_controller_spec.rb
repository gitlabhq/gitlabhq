require 'spec_helper'

describe Projects::UploadsController do
  let(:model) { create(:project, :public) }
  let(:params) do
    { namespace_id: model.namespace.to_param, project_id: model }
  end

  it_behaves_like 'handle uploads'
end
