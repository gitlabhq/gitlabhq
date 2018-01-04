require 'spec_helper'

describe PreferencesHelper do
  describe '#dashboard_choices' do
    it 'raises an exception when defined choices may be missing' do
      expect(User).to receive(:dashboards).and_return(foo: 'foo')
      expect { helper.dashboard_choices }.to raise_error(RuntimeError)
    end

    it 'raises an exception when defined choices may be using the wrong key' do
      dashboards = User.dashboards.dup
      dashboards[:projects_changed] = dashboards.delete :projects
      expect(User).to receive(:dashboards).and_return(dashboards)
      expect { helper.dashboard_choices }.to raise_error(KeyError)
    end

    it 'provides better option descriptions' do
      expect(helper.dashboard_choices).to match_array [
        ['Your Projects (default)', 'projects'],
        ['Starred Projects',        'stars'],
        ["Your Projects' Activity", 'project_activity'],
        ["Starred Projects' Activity", 'starred_project_activity'],
        ["Your Groups", 'groups'],
        ["Your Todos", 'todos']
      ]
    end
  end

  describe '#user_application_theme' do
    context 'with a user' do
      it "returns user's theme's css_class" do
        stub_user(theme_id: 3)

        expect(helper.user_application_theme).to eq 'ui_light'
      end

      it 'returns the default when id is invalid' do
        stub_user(theme_id: Gitlab::Themes.count + 5)

        allow(Gitlab.config.gitlab).to receive(:default_theme).and_return(1)

        expect(helper.user_application_theme).to eq 'ui_indigo'
      end
    end

    context 'without a user' do
      it 'returns the default theme' do
        stub_user

        expect(helper.user_application_theme).to eq Gitlab::Themes.default.css_class
      end
    end
  end

  describe '#user_color_scheme' do
    context 'with a user' do
      it "returns user's scheme's css_class" do
        allow(helper).to receive(:current_user)
          .and_return(double(color_scheme_id: 3))

        expect(helper.user_color_scheme).to eq 'solarized-light'
      end

      it 'returns the default when id is invalid' do
        allow(helper).to receive(:current_user)
          .and_return(double(color_scheme_id: Gitlab::ColorSchemes.count + 5))
      end
    end

    context 'without a user' do
      it 'returns the default theme' do
        stub_user

        expect(helper.user_color_scheme)
          .to eq Gitlab::ColorSchemes.default.css_class
      end
    end
  end

  describe '#default_project_view' do
    context 'user not signed in' do
      before do
        helper.instance_variable_set(:@project, project)
        stub_user
      end

      context 'when repository is empty' do
        let(:project) { create(:project_empty_repo, :public) }

        it 'returns activity if user has repository access' do
          allow(helper).to receive(:can?).with(nil, :download_code, project).and_return(true)

          expect(helper.default_project_view).to eq('activity')
        end

        it 'returns activity if user does not have repository access' do
          allow(helper).to receive(:can?).with(nil, :download_code, project).and_return(false)

          expect(helper.default_project_view).to eq('activity')
        end
      end

      context 'when repository is not empty' do
        let(:project) { create(:project, :public, :repository) }

        it 'returns files and readme if user has repository access' do
          allow(helper).to receive(:can?).with(nil, :download_code, project).and_return(true)

          expect(helper.default_project_view).to eq('files')
        end

        it 'returns activity if user does not have repository access' do
          allow(helper).to receive(:can?).with(nil, :download_code, project).and_return(false)

          expect(helper.default_project_view).to eq('activity')
        end
      end
    end

    context 'user signed in' do
      let(:user) { create(:user, :readme) }
      let(:project) { create(:project, :public, :repository) }

      before do
        helper.instance_variable_set(:@project, project)
        allow(helper).to receive(:current_user).and_return(user)
      end

      context 'when the user is allowed to see the code' do
        it 'returns the project view' do
          allow(helper).to receive(:can?).with(user, :download_code, project).and_return(true)

          expect(helper.default_project_view).to eq('readme')
        end
      end

      context 'with wikis enabled and the right policy for the user' do
        before do
          project.project_feature.update_attribute(:issues_access_level, 0)
          allow(helper).to receive(:can?).with(user, :download_code, project).and_return(false)
        end

        it 'returns wiki if the user has the right policy' do
          allow(helper).to receive(:can?).with(user, :read_wiki, project).and_return(true)

          expect(helper.default_project_view).to eq('wiki')
        end

        it 'returns customize_workflow if the user does not have the right policy' do
          allow(helper).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(helper.default_project_view).to eq('customize_workflow')
        end
      end

      context 'with issues as a feature available' do
        it 'return issues' do
          allow(helper).to receive(:can?).with(user, :download_code, project).and_return(false)
          allow(helper).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(helper.default_project_view).to eq('projects/issues/issues')
        end
      end

      context 'with no activity, no wikies and no issues' do
        it 'returns customize_workflow as default' do
          project.project_feature.update_attribute(:issues_access_level, 0)
          allow(helper).to receive(:can?).with(user, :download_code, project).and_return(false)
          allow(helper).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(helper.default_project_view).to eq('customize_workflow')
        end
      end
    end
  end

  def stub_user(messages = {})
    if messages.empty?
      allow(helper).to receive(:current_user).and_return(nil)
    else
      allow(helper).to receive(:current_user)
        .and_return(double('user', messages))
    end
  end
end
