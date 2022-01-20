# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Packages::InfrastructureRegistryController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }

  let(:params) { { namespace_id: project.namespace, project_id: project } }

  before do
    sign_in(user)
    project.add_maintainer(user)
  end

  describe 'GET #index' do
    subject { get :index, params: params, format: :html }

    it_behaves_like 'returning response status', :ok

    context 'when the packages registry is not available' do
      before do
        stub_config(packages: { enabled: false })
      end

      it_behaves_like 'returning response status', :not_found
    end
  end

  describe 'GET #show' do
    let_it_be(:terraform_module) { create(:terraform_module_package, project: project) }

    subject { get :show, params: params.merge(id: terraform_module.id), format: :html }

    it_behaves_like 'returning response status', :ok

    context 'when the packages registry is not available' do
      before do
        stub_config(packages: { enabled: false })
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'with package file pending destruction' do
      let_it_be(:package_file_pending_destruction) { create(:package_file, :pending_destruction, package: terraform_module) }

      let(:terraform_module_package_file) { terraform_module.package_files.first }

      it 'does not return them' do
        subject

        expect(assigns(:package_files)).to contain_exactly(terraform_module_package_file)
      end

      context 'with packages_installable_package_files disabled' do
        before do
          stub_feature_flags(packages_installable_package_files: false)
        end

        it 'returns them' do
          subject

          expect(assigns(:package_files)).to contain_exactly(package_file_pending_destruction, terraform_module_package_file)
        end
      end
    end
  end
end
