# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::ResourcesHelper, feature_category: :pipeline_composition do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { create_default(:project) }
  let_it_be(:user) { create_default(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#can_add_catalog_resource?' do
    subject { helper.can_add_catalog_resource?(project) }

    context 'when user is not an owner' do
      before_all do
        project.add_maintainer(user)
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end

    context 'when user is an owner' do
      before_all do
        project.add_owner(user)
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end
  end

  describe '#js_ci_catalog_data' do
    let(:project) { build(:project, :repository) }

    let(:default_helper_data) do
      {}
    end

    subject(:catalog_data) { helper.js_ci_catalog_data(project) }

    it 'returns catalog data' do
      expect(catalog_data).to eq(default_helper_data)
    end
  end
end
