# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::RepositoryRedirectUrlConstraint, feature_category: :source_code_management do
  subject(:constraint) { described_class.new }

  describe '#matches?' do
    subject { constraint.matches?(request) }

    let(:request) do
      env = Rack::MockRequest.env_for(
        "/#{repository_path}?#{query_string}",
        method: 'GET'
      )
      req = ActionDispatch::Request.new(env)
      allow(req).to receive(:params).and_return(
        { repository_path: repository_path }
      )
      req
    end

    context 'with valid git request' do
      let(:repository_path) { 'namespace/project.git' }

      context 'with no query string' do
        let(:query_string) { '' }

        it { is_expected.to be_truthy }
      end

      context 'with git-upload-pack service' do
        let(:query_string) { 'service=git-upload-pack' }

        it { is_expected.to be_truthy }
      end

      context 'with git-receive-pack service' do
        let(:query_string) { 'service=git-receive-pack' }

        it { is_expected.to be_truthy }
      end
    end

    context 'with invalid query string' do
      let(:repository_path) { 'namespace/project.git' }
      let(:query_string) { 'service=invalid' }

      it { is_expected.to be_falsey }
    end

    context 'with wiki path' do
      let(:repository_path) { 'namespace/project.wiki.git' }
      let(:query_string) { '' }

      it { is_expected.to be_truthy }
    end

    context 'with project path' do
      let(:repository_path) { 'namespace/project' }
      let(:query_string) { '' }

      it { is_expected.to be_truthy }
    end

    context 'with snippet path' do
      let(:repository_path) { 'snippets/123' }
      let(:query_string) { '' }

      it { is_expected.to be_truthy }
    end

    context 'with invalid path' do
      let(:repository_path) { 'invalid' }
      let(:query_string) { '' }

      it { is_expected.to be_falsey }
    end

    context 'with .git suffix removed' do
      let(:repository_path) { 'namespace/project.git' }
      let(:query_string) { '' }

      it { is_expected.to be_truthy }
    end
  end
end
