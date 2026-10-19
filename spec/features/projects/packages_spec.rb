# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Packages', feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  context 'when feature is not available' do
    context 'packages feature is disabled by config' do
      before do
        allow(Gitlab.config.packages).to receive(:enabled).and_return(false)
      end

      it 'gives 404' do
        visit_project_packages

        expect(status_code).to eq(404)
      end
    end
  end

  def visit_project_packages
    visit project_packages_path(project)
  end
end
