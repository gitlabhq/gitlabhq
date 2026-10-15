# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ProjectUrlConstraint do
  let!(:project) { create(:project) }
  let!(:namespace) { project.namespace }

  describe '#matches?' do
    context 'valid request' do
      let(:request) { build_request(namespace.full_path, project.path) }

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'invalid request' do
      context "non-existing project" do
        let(:request) { build_request('foo', 'bar') }

        it { expect(subject.matches?(request)).to be_falsey }

        context 'existence_check is false' do
          it { expect(subject.matches?(request, existence_check: false)).to be_truthy }
        end
      end

      context "project id ending with .git" do
        let(:request) { build_request(namespace.full_path, project.path + '.git') }

        it { expect(subject.matches?(request)).to be_falsey }
      end
    end

    context 'valid request for a project in an organization-scoped group' do
      let!(:organization) { create(:organization) }
      let!(:scoped_group) { create(:group, path: 'scoped', organization: organization) }
      let!(:scoped_project) { create(:project, path: 'scoped-project', namespace: scoped_group) }
      let(:request) { build_request("o/#{organization.path}/scoped", 'scoped-project') }

      before do
        # Moving the root route cascades to the project route, as a real move would.
        scoped_group.route.update!(path: "o/#{organization.path}/scoped")
      end

      it { expect(subject.matches?(request)).to be_truthy }
    end

    context 'when the request matches a redirect route' do
      let(:old_project_path) { 'old_project_path' }
      let!(:redirect_route) { project.redirect_routes.create!(path: "#{namespace.full_path}/#{old_project_path}") }

      context 'and is a GET request' do
        let(:request) { build_request(namespace.full_path, old_project_path) }

        it { expect(subject.matches?(request)).to be_truthy }
      end

      context 'and is NOT a GET request' do
        let(:request) { build_request(namespace.full_path, old_project_path, 'POST') }

        it { expect(subject.matches?(request)).to be_falsey }
      end
    end
  end

  def build_request(namespace, project, method = 'GET')
    double(:request,
      get?: (method == 'GET'),
      params: { namespace_id: namespace, id: project })
  end
end
