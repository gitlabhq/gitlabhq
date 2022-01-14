# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::PackagesController do
  let_it_be(:group) { create(:group) }

  let(:page) { :index }
  let(:additional_parameters) { {} }

  subject do
    get page, params: additional_parameters.merge({
      group_id: group
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
