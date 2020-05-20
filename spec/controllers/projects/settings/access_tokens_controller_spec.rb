# frozen_string_literal: true

require('spec_helper')

describe Projects::Settings::AccessTokensController do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  shared_examples 'feature unavailability' do
    context 'when flag is disabled' do
      before do
        stub_feature_flags(resource_access_token: false)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when environment is Gitlab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end
  end

  describe '#index' do
    subject { get :index, params: { namespace_id: project.namespace, project_id: project } }

    it_behaves_like 'feature unavailability'

    context 'when feature is available' do
      let_it_be(:bot_user) { create(:user, :project_bot) }
      let_it_be(:active_project_access_token) { create(:personal_access_token, user: bot_user) }
      let_it_be(:inactive_project_access_token) { create(:personal_access_token, :revoked, user: bot_user) }

      before_all do
        project.add_maintainer(bot_user)
      end

      before do
        enable_feature
      end

      it 'retrieves active project access tokens' do
        subject

        expect(assigns(:active_project_access_tokens)).to contain_exactly(active_project_access_token)
      end

      it 'retrieves inactive project access tokens' do
        subject

        expect(assigns(:inactive_project_access_tokens)).to contain_exactly(inactive_project_access_token)
      end

      it 'lists all available scopes' do
        subject

        expect(assigns(:scopes)).to eq(Gitlab::Auth.resource_bot_scopes)
      end

      it 'retrieves newly created personal access token value' do
        token_value = 'random-value'
        allow(PersonalAccessToken).to receive(:redis_getdel).with("#{user.id}:#{project.id}").and_return(token_value)

        subject

        expect(assigns(:new_project_access_token)).to eq(token_value)
      end
    end
  end

  describe '#create', :clean_gitlab_redis_shared_state do
    subject { post :create, params: { namespace_id: project.namespace, project_id: project }.merge(project_access_token: access_token_params) }

    let_it_be(:access_token_params) { {} }

    it_behaves_like 'feature unavailability'

    context 'when feature is available' do
      let_it_be(:access_token_params) { { name: 'Nerd bot', scopes: ["api"], expires_at: 1.month.since.to_date } }

      before do
        enable_feature
      end

      def created_token
        PersonalAccessToken.order(:created_at).last
      end

      it 'returns success message' do
        subject

        expect(response.flash[:notice]).to match(/\AYour new project access token has been created./i)
      end

      it 'creates project access token' do
        subject

        expect(created_token.name).to eq(access_token_params[:name])
        expect(created_token.scopes).to eq(access_token_params[:scopes])
        expect(created_token.expires_at).to eq(access_token_params[:expires_at])
      end

      it 'creates project bot user' do
        subject

        expect(created_token.user).to be_project_bot
      end

      it 'stores newly created token redis store' do
        expect(PersonalAccessToken).to receive(:redis_store!)

        subject
      end

      it { expect { subject }.to change { User.count }.by(1) }
      it { expect { subject }.to change { PersonalAccessToken.count }.by(1) }

      context 'when unsuccessful' do
        before do
          allow_next_instance_of(ResourceAccessTokens::CreateService) do |service|
            allow(service).to receive(:execute).and_return ServiceResponse.error(message: 'Failed!')
          end
        end

        it { expect(subject).to render_template(:index) }
      end
    end
  end

  describe '#revoke' do
    subject { put :revoke, params: { namespace_id: project.namespace, project_id: project, id: project_access_token } }

    let_it_be(:bot_user) { create(:user, :project_bot) }
    let_it_be(:project_access_token) { create(:personal_access_token, user: bot_user) }

    before_all do
      project.add_maintainer(bot_user)
    end

    it_behaves_like 'feature unavailability'

    context 'when feature is available' do
      before do
        enable_feature
      end

      it 'revokes token access' do
        subject

        expect(project_access_token.reload.revoked?).to be true
      end

      it 'removed membership of bot user' do
        subject

        expect(project.reload.bots).not_to include(bot_user)
      end

      it 'blocks project bot user' do
        subject

        expect(bot_user.reload.blocked?).to be true
      end

      it 'converts issuables of the bot user to ghost user' do
        issue = create(:issue, author: bot_user)

        subject

        expect(issue.reload.author.ghost?).to be true
      end
    end
  end

  def enable_feature
    allow(Gitlab).to receive(:com?).and_return(false)
    stub_feature_flags(resource_access_token: true)
  end
end
