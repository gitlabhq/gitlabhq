require 'spec_helper'

describe PreferencesHelper do
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
