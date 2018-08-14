require 'rails_helper'

describe ImportHelper do
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

  describe '#provider_project_link' do
    context 'when provider is "github"' do
      let(:github_server_url) { nil }
      let(:provider) { OpenStruct.new(name: 'github', url: github_server_url) }

      before do
        stub_omniauth_setting(providers: [provider])
      end

      context 'when provider does not specify a custom URL' do
        it 'uses default GitHub URL' do
          expect(helper.provider_project_link('github', 'octocat/Hello-World'))
          .to include('href="https://github.com/octocat/Hello-World"')
        end
      end

      context 'when provider specify a custom URL' do
        let(:github_server_url) { 'https://github.company.com' }

        it 'uses custom URL' do
          expect(helper.provider_project_link('github', 'octocat/Hello-World'))
          .to include('href="https://github.company.com/octocat/Hello-World"')
        end
      end

      context "when custom URL contains a '/' char at the end" do
        let(:github_server_url) { 'https://github.company.com/' }

        it "doesn't render double slash" do
          expect(helper.provider_project_link('github', 'octocat/Hello-World'))
          .to include('href="https://github.company.com/octocat/Hello-World"')
        end
      end

      context 'when provider is missing' do
        it 'uses the default URL' do
          allow(Gitlab.config.omniauth).to receive(:providers).and_return([])

          expect(helper.provider_project_link('github', 'octocat/Hello-World'))
          .to include('href="https://github.com/octocat/Hello-World"')
        end
      end
    end

    context 'when provider is "gitea"' do
      before do
        assign(:gitea_host_url, 'https://try.gitea.io/')
      end

      it 'uses given host' do
        expect(helper.provider_project_link('gitea', 'octocat/Hello-World'))
        .to include('href="https://try.gitea.io/octocat/Hello-World"')
      end
    end
  end
end
