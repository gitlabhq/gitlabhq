# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PreferencesHelper, feature_category: :shared do
  let_it_be(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '#dashboard_value' do
    context 'when feature flag your_work_projects_vue is enabled' do
      it 'returns dashboard of current user' do
        allow(user).to receive(:dashboard).and_return('your_activity')

        expect(helper.dashboard_value).to eq('your_activity')
      end
    end

    context 'when feature flag your_work_projects_vue is disabled' do
      before do
        stub_feature_flags(your_work_projects_vue: false)
      end

      context 'when dashboard of current user is member_projects' do
        it 'returns projects' do
          allow(user).to receive(:dashboard).and_return('member_projects')

          expect(helper.dashboard_value).to eq('projects')
        end
      end

      context 'when dashboard of current user is not member_projects' do
        it 'returns projects' do
          allow(user).to receive(:dashboard).and_return('your_activity')

          expect(helper.dashboard_value).to eq('your_activity')
        end
      end
    end
  end

  describe '#dashboard_choices' do
    before do
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

    context 'when feature flag your_work_projects_vue is enabled' do
      it 'returns expected options' do
        expect(helper.dashboard_choices).to match_array [
          { text: "Your Contributed Projects (default)", value: 'projects' },
          { text: "Starred Projects", value: 'stars' },
          { text: "Member Projects", value: 'member_projects' },
          { text: "Your Activity", value: 'your_activity' },
          { text: "Your Projects' Activity", value: 'project_activity' },
          { text: "Starred Projects' Activity", value: 'starred_project_activity' },
          { text: "Followed Users' Activity", value: 'followed_user_activity' },
          { text: "Your Groups", value: 'groups' },
          { text: "Your To-Do List", value: 'todos' },
          { text: "Assigned issues", value: 'issues' },
          { text: "Assigned merge requests", value: 'merge_requests' }
        ]
      end
    end

    context 'when feature flag your_work_projects_vue is disabled' do
      before do
        stub_feature_flags(your_work_projects_vue: false)
      end

      it 'returns expected options' do
        expect(helper.dashboard_choices).to match_array [
          { text: "Your Projects (default)", value: 'projects' },
          { text: "Starred Projects", value: 'stars' },
          { text: "Your Activity", value: 'your_activity' },
          { text: "Your Projects' Activity", value: 'project_activity' },
          { text: "Starred Projects' Activity", value: 'starred_project_activity' },
          { text: "Followed Users' Activity", value: 'followed_user_activity' },
          { text: "Your Groups", value: 'groups' },
          { text: "Your To-Do List", value: 'todos' },
          { text: "Assigned issues", value: 'issues' },
          { text: "Assigned merge requests", value: 'merge_requests' }
        ]
      end
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

  describe '#time_display_format_choices_with_default' do
    it 'returns choices' do
      expect(helper.time_display_format_choices).to eq({
        "12-hour: 2:34 PM" => 1,
        "24-hour: 14:34" => 2,
        "System" => 0
      })
    end
  end

  describe '#user_application_theme' do
    context 'with a user' do
      it "returns user's theme's css_class" do
        stub_user(theme_id: 3)

        expect(helper.user_application_theme).to eq 'ui-neutral'
      end

      it 'returns the default when id is invalid', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444873' do
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

  describe '#user_application_dark_mode?' do
    context 'with a user' do
      it "returns true if user's selected dark mode" do
        stub_user(color_mode_id: 2)

        expect(helper.user_application_dark_mode?).to eq true
      end

      it "returns false if user's selected light mode" do
        stub_user(color_mode_id: 1)

        expect(helper.user_application_dark_mode?).to eq false
      end
    end

    context 'without a user' do
      it 'returns false' do
        stub_user

        expect(helper.user_application_dark_mode?).to eq false
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

  describe '#user_diffs_colors' do
    context 'with a user' do
      it "returns user's diffs colors" do
        stub_user(diffs_addition_color: '#123456', diffs_deletion_color: '#abcdef')

        expect(helper.user_diffs_colors).to eq({ addition: '#123456', deletion: '#abcdef' })
      end

      it 'omits property if nil' do
        stub_user(diffs_addition_color: '#123456', diffs_deletion_color: nil)

        expect(helper.user_diffs_colors).to eq({ addition: '#123456' })
      end

      it 'omits property if blank' do
        stub_user(diffs_addition_color: '', diffs_deletion_color: '#abcdef')

        expect(helper.user_diffs_colors).to eq({ deletion: '#abcdef' })
      end
    end

    context 'without a user' do
      it 'returns no properties' do
        stub_user

        expect(helper.user_diffs_colors).to eq({})
      end
    end
  end

  describe '#custom_diff_color_classes' do
    context 'with a user' do
      it 'returns color classes' do
        stub_user(diffs_addition_color: '#123456', diffs_deletion_color: '#abcdef')

        expect(helper.custom_diff_color_classes)
          .to match_array(%w[diff-custom-addition-color diff-custom-deletion-color])
      end

      it 'omits property if nil' do
        stub_user(diffs_addition_color: '#123456', diffs_deletion_color: nil)

        expect(helper.custom_diff_color_classes).to match_array(['diff-custom-addition-color'])
      end

      it 'omits property if blank' do
        stub_user(diffs_addition_color: '', diffs_deletion_color: '#abcdef')

        expect(helper.custom_diff_color_classes).to match_array(['diff-custom-deletion-color'])
      end
    end

    context 'without a user' do
      it 'returns no classes' do
        stub_user

        expect(helper.custom_diff_color_classes).to be_empty
      end
    end
  end

  describe '#language_choices' do
    include StubLanguagesTranslationPercentage

    it 'lists all the selectable language options with their translation percent' do
      stub_languages_translation_percentage(en: 100, es: 65)
      stub_user(preferred_language: :en)

      expect(helper.language_choices).to eq([
        { text: "English (100% translated)", value: 'en' },
        { text: "Spanish - español (65% translated)", value: 'es' }
      ])
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
    let(:gitpod_enabled) { false }

    before do
      allow(Gitlab::CurrentSettings).to receive(:gitpod_enabled).and_return(gitpod_enabled)
      allow(Gitlab::CurrentSettings).to receive(:gitpod_url).and_return(gitpod_url)
    end

    context 'on default' do
      it 'includes integration views' do
        expect(helper.integration_views).to be_empty
      end

      context 'when Web IDE Extension Marketplace feature is enabled' do
        before do
          allow(::WebIde::ExtensionsMarketplace).to receive(:feature_enabled?).with(user: user).and_return(true)
        end

        it 'includes extension marketplace integration' do
          expect(helper.integration_views).to include(
            a_hash_including({
              name: 'extensions_marketplace',
              message: 'Uses %{linkStart}https://open-vsx.org%{linkEnd} as the extension marketplace ' \
                'for the Web IDE.',
              message_url: 'https://open-vsx.org'
            })
          )
        end
      end

      it 'does not include extensions_marketplace' do
        expect(helper.integration_views).not_to match(a_hash_including(name: 'extensions_marketplace'))
      end
    end

    context 'when Gitpod is enabled' do
      let(:gitpod_enabled) { true }

      it 'includes Gitpod integration' do
        expect(helper.integration_views).to include(
          a_hash_including({ name: 'gitpod', message_url: gitpod_url })
        )
      end

      context 'when Gitpod url is not set' do
        let(:gitpod_url) { '' }

        it 'includes Gitpod integration with default url' do
          expect(helper.integration_views).to include(
            a_hash_including({ name: 'gitpod', message_url: 'https://gitpod.io/' })
          )
        end
      end
    end
  end
end
