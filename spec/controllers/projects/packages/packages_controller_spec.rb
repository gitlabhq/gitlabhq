# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Packages::PackagesController, feature_category: :package_registry do
  let_it_be(:project) { create(:project, :public) }

  let(:page) { :index }
  let(:additional_parameters) { {} }

  subject do
    get page, params: additional_parameters.merge({
      project_id: project,
      namespace_id: project.namespace
    })
  end

  context 'GET #index' do
    it_behaves_like 'returning response status', :ok
  end

  context 'GET #show' do
    let(:page) { :show }
    let(:additional_parameters) { { id: 1 } }

    it_behaves_like 'returning response status', :ok
  end
end
