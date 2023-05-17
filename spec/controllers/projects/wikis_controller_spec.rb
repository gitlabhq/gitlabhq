# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::WikisController, feature_category: :wiki do
  it_behaves_like 'wiki controller actions' do
    let(:container) { create(:project, :public, namespace: user.namespace) }
    let(:routing_params) { { namespace_id: container.namespace, project_id: container } }
  end
end
