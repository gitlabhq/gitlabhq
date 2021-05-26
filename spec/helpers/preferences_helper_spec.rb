# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreferencesHelper do
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
        ["Followed Users' Activity", 'followed_user_activity'],
        ["Your Groups", 'groups'],
        ["Your To-Do List", 'todos'],
        ["Assigned Issues", 'issues'],
        ["Assigned merge requests", 'merge_requests']
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
    include StubLanguagesTranslationPercentage

    it 'lists all the selectable language options with their translation percent' do
      stub_languages_translation_percentage(en: 100, es: 65)
      stub_user(preferred_language: :en)

      expect(helper.language_choices).to eq([
        '<option selected="selected" value="en">English (100% translated)</option>',
        '<option value="es">Spanish - español (65% translated)</option>'
      ].join("\n"))
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

  describe '#integration_views' do
    let(:gitpod_url) { 'http://gitpod.test' }

    before do
      allow(Gitlab::CurrentSettings).to receive(:gitpod_enabled).and_return(gitpod_enabled)
      allow(Gitlab::CurrentSettings).to receive(:gitpod_url).and_return(gitpod_url)
    end

    context 'when Gitpod is not enabled' do
      let(:gitpod_enabled) { false }

      it 'does not include Gitpod integration' do
        expect(helper.integration_views).to be_empty
      end
    end

    context 'when Gitpod is enabled' do
      let(:gitpod_enabled) { true }

      it 'includes Gitpod integration' do
        expect(helper.integration_views[0][:name]).to eq 'gitpod'
      end

      it 'returns the Gitpod url configured in settings' do
        expect(helper.integration_views[0][:message_url]).to eq gitpod_url
      end

      context 'when Gitpod url is not set' do
        let(:gitpod_url) { '' }

        it 'returns the Gitpod default url' do
          expect(helper.integration_views[0][:message_url]).to eq 'https://gitpod.io/'
        end
      end
    end
  end
end
