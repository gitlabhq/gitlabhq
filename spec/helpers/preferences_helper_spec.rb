require 'spec_helper'

describe PreferencesHelper do
  describe 'dashboard_choices' do
    it 'raises an exception when defined choices may be missing' do
      dashboards = User.dashboards
      expect(User).to receive(:dashboards).
        and_return(dashboards.merge(foo: 'foo'))

      expect { dashboard_choices }.to raise_error
    end

    it 'provides better option descriptions' do
      choices = dashboard_choices

      expect(choices[0]).to eq ['Your Projects (default)', 'projects']
      expect(choices[1]).to eq ['Starred Projects',        'stars']
    end
  end
end
