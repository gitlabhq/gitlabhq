# frozen_string_literal: true

require "spec_helper"

RSpec.describe Groups::ObservabilityHelper do
  let(:group) { build_stubbed(:group) }

  describe '#observability_iframe_src' do
    before do
      allow(Gitlab::Observability).to receive(:build_full_url).and_return('full-url')
    end

    it 'returns the iframe src for action: dashboards' do
      allow(helper).to receive(:params).and_return({ action: 'dashboards', observability_path: '/foo?bar=foobar' })
      expect(helper.observability_iframe_src(group)).to eq('full-url')
      expect(Gitlab::Observability).to have_received(:build_full_url).with(group, '/foo?bar=foobar', '/')
    end

    it 'returns the iframe src for action: manage' do
      allow(helper).to receive(:params).and_return({ action: 'manage', observability_path: '/foo?bar=foobar' })
      expect(helper.observability_iframe_src(group)).to eq('full-url')
      expect(Gitlab::Observability).to have_received(:build_full_url).with(group, '/foo?bar=foobar', '/dashboards')
    end

    it 'returns the iframe src for action: explore' do
      allow(helper).to receive(:params).and_return({ action: 'explore', observability_path: '/foo?bar=foobar' })
      expect(helper.observability_iframe_src(group)).to eq('full-url')
      expect(Gitlab::Observability).to have_received(:build_full_url).with(group, '/foo?bar=foobar', '/explore')
    end

    it 'returns the iframe src for action: datasources' do
      allow(helper).to receive(:params).and_return({ action: 'datasources', observability_path: '/foo?bar=foobar' })
      expect(helper.observability_iframe_src(group)).to eq('full-url')
      expect(Gitlab::Observability).to have_received(:build_full_url).with(group, '/foo?bar=foobar', '/datasources')
    end

    it 'returns the iframe src when action is not recognised' do
      allow(helper).to receive(:params).and_return({ action: 'unrecognised', observability_path: '/foo?bar=foobar' })
      expect(helper.observability_iframe_src(group)).to eq('full-url')
      expect(Gitlab::Observability).to have_received(:build_full_url).with(group, '/foo?bar=foobar', '/')
    end

    it 'returns the iframe src when observability_path is missing' do
      allow(helper).to receive(:params).and_return({ action: 'dashboards' })
      expect(helper.observability_iframe_src(group)).to eq('full-url')
      expect(Gitlab::Observability).to have_received(:build_full_url).with(group, nil, '/')
    end
  end

  describe '#observability_page_title' do
    it 'returns the title for action: dashboards' do
      allow(helper).to receive(:params).and_return({ action: 'dashboards' })
      expect(helper.observability_page_title).to eq("Dashboards")
    end

    it 'returns the title for action: manage' do
      allow(helper).to receive(:params).and_return({ action: 'manage' })
      expect(helper.observability_page_title).to eq("Manage dashboards")
    end

    it 'returns the title for action: explore' do
      allow(helper).to receive(:params).and_return({ action: 'explore' })
      expect(helper.observability_page_title).to eq("Explore telemetry data")
    end

    it 'returns the title for action: datasources' do
      allow(helper).to receive(:params).and_return({ action: 'datasources' })
      expect(helper.observability_page_title).to eq("Data sources")
    end

    it 'returns the default title for unknown action' do
      allow(helper).to receive(:params).and_return({ action: 'unknown' })
      expect(helper.observability_page_title).to eq("Dashboards")
    end
  end
end
