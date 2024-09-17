# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportHelper, feature_category: :importers do
  describe '#sanitize_project_name' do
    it 'removes leading tildes' do
      expect(helper.sanitize_project_name('~~root')).to eq('root')
    end

    it 'removes whitespace' do
      expect(helper.sanitize_project_name('my test repo')).to eq('my-test-repo')
    end

    it 'removes disallowed characters' do
      expect(helper.sanitize_project_name('Test&me$over*h_ere')).to eq('Test-me-over-h_ere')
    end
  end

  describe '#import_project_target' do
    let(:user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'when current user can create namespaces' do
      it 'returns project namespace' do
        user.update_attribute(:can_create_group, true)

        expect(helper.import_project_target('asd', 'vim')).to eq 'asd/vim'
      end
    end

    context 'when current user can not create namespaces' do
      it "takes the current user's namespace" do
        user.update_attribute(:can_create_group, false)

        expect(helper.import_project_target('asd', 'vim')).to eq "#{user.namespace_path}/vim"
      end
    end
  end

  describe '#provider_project_link_url' do
    let(:full_path) { '/repo/path' }
    let(:host_url) { 'http://provider.com/' }

    it 'appends repo full path to provider host url' do
      expect(helper.provider_project_link_url(host_url, full_path)).to match('http://provider.com/repo/path')
    end
  end

  describe '#import_configure_github_admin_message' do
    subject { helper.import_configure_github_admin_message }

    it 'returns note for admin' do
      allow(helper).to receive(:current_user) { instance_double('User', can_admin_all_resources?: true) }

      is_expected.to have_text('Note: As an administrator')
    end

    it 'returns note for other user' do
      allow(helper).to receive(:current_user) { instance_double('User', can_admin_all_resources?: false) }

      is_expected.to have_text('Note: Consider asking your GitLab administrator')
    end
  end
end
