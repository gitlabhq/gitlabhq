# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['User'], feature_category: :user_profile do
  specify { expect(described_class.graphql_name).to eq('User') }
  specify { expect(described_class.interfaces).to include(Types::TodoableInterface) }

  specify do
    runtime_type = described_class.resolve_type(build(:user), {})

    expect(runtime_type).to require_graphql_authorizations(:read_user)
  end

  it 'has the expected fields' do
    expected_fields = %w[
      id
      bot
      active
      human
      user_permissions
      snippets
      name
      username
      email
      emails
      publicEmail
      commitEmail
      namespaceCommitEmails
      avatarUrl
      webUrl
      webPath
      todos
      state
      status
      location
      authoredMergeRequests
      assignedMergeRequests
      reviewRequestedMergeRequests
      groupMemberships
      groupCount
      projectMemberships
      starredProjects
      contributedProjects
      callouts
      namespace
      timelogs
      groups
      gitpodEnabled
      preferencesGitpodPath
      profileEnableGitpodPath
      savedReplies
      savedReply
      userAchievements
      bio
      linkedin
      twitter
      discord
      organization
      jobTitle
      createdAt
      lastActivityOn
      pronouns
      ide
      userPreferences
      type
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end

  describe 'name field' do
    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:user) { create(:user) }
    let_it_be(:requested_user) { create(:user, name: 'John Smith') }
    let_it_be(:requested_project_bot) { create(:user, :project_bot, name: 'Project bot') }
    let_it_be(:requested_group_bot) { create(:user, :project_bot, name: 'Group bot') }
    let_it_be(:requested_project_service_account) { create(:user, :service_account, name: 'Project service account') }
    let_it_be(:requested_group_service_account) { create(:user, :service_account, name: 'Group service account') }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:group) { create(:group, :public) }

    before do
      project.add_maintainer(requested_project_bot)
      group.add_maintainer(requested_group_bot)
    end

    let(:username) { requested_user.username }

    let(:query) do
      <<~GQL
        query {
          user(username: "#{username}") {
            name
          }
        }
      GQL
    end

    subject(:user_name) do
      GitlabSchema.execute(query, context: { current_user: current_user }).as_json.dig('data', 'user', 'name')
    end

    context 'user requests' do
      let(:current_user) { user }

      context 'a user' do
        it 'returns name' do
          expect(user_name).to eq('John Smith')
        end
      end

      context 'a project bot' do
        let(:username) { requested_project_bot.username }

        context 'when requester is nil' do
          let(:current_user) { nil }

          it 'returns nothing' do
            expect(user_name).to be_nil
          end
        end

        context 'when the requester is not a project member' do
          it 'returns `Project bot` for a non project member in a public project' do
            expect(user_name).to eq('Project bot')
          end

          context 'in a private project' do
            let(:project) { create(:project, :private) }

            it 'returns `****` for a non project member in a private project' do
              expect(user_name).to eq('****')
            end
          end
        end

        context 'with a project member' do
          before do
            project.add_guest(user)
          end

          it 'returns `Project bot` for a project member' do
            expect(user_name).to eq('Project bot')
          end

          context 'in a private project' do
            let(:project) { create(:project, :private) }

            it 'returns `Project bot` for a project member in a private project' do
              expect(user_name).to eq('Project bot')
            end
          end
        end

        context 'a group bot' do
          let(:username) { requested_group_bot.username }

          context 'when requester is nil' do
            let(:current_user) { nil }

            it 'returns nothing' do
              expect(user_name).to be_nil
            end
          end

          context 'when the requester is not a group member' do
            it 'returns `Group bot` for a non group member in a public group' do
              expect(user_name).to eq('Group bot')
            end

            context 'in a private group' do
              let(:group) { create(:group, :private) }

              it 'returns `****` for a non group member in a private group' do
                expect(user_name).to eq('****')
              end
            end
          end

          context 'with a group member' do
            before do
              group.add_guest(user)
            end

            it 'returns `Group bot` for a group member' do
              expect(user_name).to eq('Group bot')
            end

            context 'in a private group' do
              let(:group) { create(:group, :private) }

              it 'returns `Group bot` for a group member in a private group' do
                expect(user_name).to eq('Group bot')
              end
            end
          end
        end
      end

      context 'a project service account' do
        let(:username) { requested_project_service_account.username }

        context 'when requester is nil' do
          let(:current_user) { nil }

          it 'returns nothing' do
            expect(user_name).to be_nil
          end
        end

        context 'when the requester is not a project member' do
          it 'returns `Project service account` for a non project member in a public project' do
            expect(user_name).to eq('Project service account')
          end
        end

        context 'with a project member' do
          before do
            project.add_guest(user)
          end

          it 'returns `Project service account` for a project member' do
            expect(user_name).to eq('Project service account')
          end

          context 'in a private project' do
            let(:project) { create(:project, :private) }

            it 'returns `Project service account` for a project member in a private project' do
              expect(user_name).to eq('Project service account')
            end
          end
        end

        context 'a group service account' do
          let(:username) { requested_group_service_account.username }

          context 'when requester is nil' do
            let(:current_user) { nil }

            it 'returns nothing' do
              expect(user_name).to be_nil
            end
          end

          context 'when the requester is not a group member' do
            it 'returns `Group service account` for a non group member in a public group' do
              expect(user_name).to eq('Group service account')
            end
          end

          context 'with a group member' do
            before do
              group.add_guest(user)
            end

            it 'returns `Group service account` for a group member' do
              expect(user_name).to eq('Group service account')
            end

            context 'in a private group' do
              let(:group) { create(:group, :private) }

              it 'returns `Group service account` for a group member in a private group' do
                expect(user_name).to eq('Group service account')
              end
            end
          end
        end
      end
    end

    context 'admin requests', :enable_admin_mode do
      let(:current_user) { admin }

      context 'a user' do
        it 'returns name' do
          expect(subject).to eq('John Smith')
        end
      end

      context 'a project bot' do
        let(:username) { requested_project_bot.username }

        it 'returns name' do
          expect(subject).to eq('Project bot')
        end
      end

      context 'a group bot' do
        let(:username) { requested_group_bot.username }

        it 'returns name' do
          expect(subject).to eq('Group bot')
        end
      end

      context 'a project service account' do
        let(:username) { requested_project_service_account.username }

        it 'returns name' do
          expect(subject).to eq('Project service account')
        end
      end

      context 'a group service account' do
        let(:username) { requested_group_service_account.username }

        it 'returns name' do
          expect(subject).to eq('Group service account')
        end
      end
    end
  end

  describe 'snippets field' do
    subject { described_class.fields['snippets'] }

    it 'returns snippets' do
      is_expected.to have_graphql_type(Types::SnippetType.connection_type)
      is_expected.to have_graphql_resolver(Resolvers::Users::SnippetsResolver)
    end
  end

  describe 'callouts field' do
    subject { described_class.fields['callouts'] }

    it 'returns user callouts' do
      is_expected.to have_graphql_type(Types::UserCalloutType.connection_type)
    end
  end

  describe 'timelogs field' do
    subject { described_class.fields['timelogs'] }

    it 'returns user timelogs' do
      is_expected.to have_graphql_resolver(Resolvers::TimelogResolver)
      is_expected.to have_graphql_type(Types::TimelogType.connection_type)
    end
  end

  describe 'emails field' do
    subject { described_class.fields['emails'] }

    it 'returns user emails' do
      is_expected.to have_graphql_type(Types::Users::EmailType.connection_type)
    end
  end

  describe 'namespaceCommitEmails field' do
    subject { described_class.fields['namespaceCommitEmails'] }

    it 'returns user namespace_commit_emails' do
      is_expected.to have_graphql_type(Types::Users::NamespaceCommitEmailType.connection_type)
    end
  end

  describe 'ide field' do
    subject { described_class.fields['ide'] }

    it 'returns ide' do
      is_expected.to have_graphql_type(Types::IdeType)
    end

    context 'code suggestions enabled' do
      let(:current_user) { create(:user) }
      let(:query) do
        <<~GQL
        query {
          currentUser {
            ide {
              codeSuggestionsEnabled
            }
          }
        }
        GQL
      end

      subject(:code_suggestions_enabled) do
        GitlabSchema.execute(query, context: { current_user: current_user })
          .as_json
          .dig('data', 'currentUser', 'ide', 'codeSuggestionsEnabled')
      end

      it 'returns code suggestions enabled' do
        allow(current_user).to receive(:can?).with(:access_code_suggestions).and_return(true)

        expect(current_user).to receive(:can?).with(:access_code_suggestions).and_return(true)
        expect(code_suggestions_enabled).to be true
      end
    end
  end

  describe 'userPreferences field' do
    subject { described_class.fields['userPreferences'] }

    it 'returns userPreferences field' do
      is_expected.to have_graphql_type(Types::UserPreferencesType)
    end
  end

  describe 'type field' do
    subject { described_class.fields['type'] }

    let_it_be(:admin) { create(:user, :admin) }
    let_it_be(:regular_user) { create(:user) }
    let_it_be(:placeholder_user) { create(:user, :placeholder) }
    let_it_be(:import_user) { create(:user, :import_user) }
    let_it_be(:ghost_user) { create(:user, :ghost) }

    let(:query) do
      <<~GQL
      query($id: UserID!) {
        user(id: $id) {
          type
        }
      }
      GQL
    end

    it 'returns type field' do
      is_expected.to have_graphql_type(Types::Users::TypeEnum.to_non_null_type)
    end

    it 'returns HUMAN for regular users' do
      result = GitlabSchema.execute(query, variables: { id: regular_user.to_global_id.to_s },
        context: { current_user: admin }).as_json

      expect(result.dig('data', 'user', 'type')).to eq('HUMAN')
    end

    it 'returns PLACEHOLDER for placeholder users' do
      result = GitlabSchema.execute(query, variables: { id: placeholder_user.to_global_id.to_s },
        context: { current_user: admin }).as_json

      expect(result.dig('data', 'user', 'type')).to eq('PLACEHOLDER')
    end

    it 'returns IMPORT_USER for import users' do
      result = GitlabSchema.execute(query, variables: { id: import_user.to_global_id.to_s },
        context: { current_user: admin }).as_json

      expect(result.dig('data', 'user', 'type')).to eq('IMPORT_USER')
    end

    it 'returns GHOST for ghost users' do
      result = GitlabSchema.execute(query, variables: { id: ghost_user.to_global_id.to_s },
        context: { current_user: admin }).as_json

      expect(result.dig('data', 'user', 'type')).to eq('GHOST')
    end
  end
end
