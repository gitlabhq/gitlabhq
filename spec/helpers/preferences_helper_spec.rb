require 'spec_helper'

describe PreferencesHelper do
  describe '#dashboard_choices' do
    let(:user) { build(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(false)
    end

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
        ["Your To-Do List", 'todos'],
        ["Assigned Issues", 'issues'],
        ["Assigned Merge Requests", 'merge_requests']
      ]
    end
  end

  describe '#first_day_of_week_choices' do
    it 'returns Saturday, Sunday and Monday as choices' do
      expect(helper.first_day_of_week_choices).to eq [
        ['Sunday', 0],
        ['Monday', 1],
        ['Saturday', 6]
      ]
    end
  end

  describe '#first_day_of_week_choices_with_default' do
    it 'returns choices including system default' do
      expect(helper.first_day_of_week_choices_with_default).to eq [
        ['System default (Sunday)', nil], ['Sunday', 0], ['Monday', 1], ['Saturday', 6]
      ]
    end

    it 'returns choices including system default set to Monday' do
      stub_application_setting(first_day_of_week: 1)
      expect(helper.first_day_of_week_choices_with_default).to eq [
        ['System default (Monday)', nil], ['Sunday', 0], ['Monday', 1], ['Saturday', 6]
      ]
    end

    it 'returns choices including system default set to Saturday' do
      stub_application_setting(first_day_of_week: 6)
      expect(helper.first_day_of_week_choices_with_default).to eq [
        ['System default (Saturday)', nil], ['Sunday', 0], ['Monday', 1], ['Saturday', 6]
      ]
    end
  end

  describe '#user_application_theme' do
    context 'with a user' do
      it "returns user's theme's css_class" do
        stub_user(theme_id: 3)

        expect(helper.user_application_theme).to eq 'ui-light'
      end

      it 'returns the default when id is invalid' do
        stub_user(theme_id: Gitlab::Themes.count + 5)

        allow(Gitlab.config.gitlab).to receive(:default_theme).and_return(1)

        expect(helper.user_application_theme).to eq 'ui-indigo'
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

  describe '#language_choices' do
    it 'returns an array of all available languages' do
      expect(helper.language_choices).to be_an(Array)
      expect(helper.language_choices.map(&:second)).to eq(Gitlab::I18n.available_locales)
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
