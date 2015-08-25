require 'spec_helper'

describe PreferencesHelper do
  describe 'user_application_theme' do
    context 'with a user' do
      it "returns user's theme's css_class" do
        user = double('user', theme_id: 3)
        allow(self).to receive(:current_user).and_return(user)
        expect(user_application_theme).to eq 'ui_green'
      end

      it 'returns the default when id is invalid' do
        user = double('user', theme_id: Gitlab::Themes::THEMES.size + 5)

        allow(Gitlab.config.gitlab).to receive(:default_theme).and_return(2)
        allow(self).to receive(:current_user).and_return(user)

        expect(user_application_theme).to eq 'ui_charcoal'
      end
    end

    context 'without a user' do
      before do
        allow(self).to receive(:current_user).and_return(nil)
      end

      it 'returns the default theme' do
        expect(user_application_theme).to eq Gitlab::Themes.default.css_class
      end
    end
  end

  describe 'dashboard_choices' do
    it 'raises an exception when defined choices may be missing' do
      expect(User).to receive(:dashboards).and_return(foo: 'foo')
      expect { dashboard_choices }.to raise_error(RuntimeError)
    end

    it 'raises an exception when defined choices may be using the wrong key' do
      expect(User).to receive(:dashboards).and_return(foo: 'foo', bar: 'bar')
      expect { dashboard_choices }.to raise_error(KeyError)
    end

    it 'provides better option descriptions' do
      expect(dashboard_choices).to match_array [
        ['Your Projects (default)', 'projects'],
        ['Starred Projects',        'stars']
      ]
    end
  end
end
