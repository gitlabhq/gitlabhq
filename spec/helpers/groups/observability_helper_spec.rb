# frozen_string_literal: true

require "spec_helper"

RSpec.describe Groups::ObservabilityHelper do
  let(:group) { build_stubbed(:group) }
  let(:observability_url) { Gitlab::Observability.observability_url }

  describe '#observability_iframe_src' do
    context 'if observability_path is missing from params' do
      it 'returns the iframe src for action: dashboards' do
        allow(helper).to receive(:params).and_return({ action: 'dashboards' })
        expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/-/#{group.id}/")
      end

      it 'returns the iframe src for action: manage' do
        allow(helper).to receive(:params).and_return({ action: 'manage' })
        expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/-/#{group.id}/dashboards")
      end

      it 'returns the iframe src for action: explore' do
        allow(helper).to receive(:params).and_return({ action: 'explore' })
        expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/-/#{group.id}/explore")
      end

      it 'returns the iframe src for action: datasources' do
        allow(helper).to receive(:params).and_return({ action: 'datasources' })
        expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/-/#{group.id}/datasources")
      end
    end

    context 'if observability_path exists in params' do
      context 'if observability_path is valid' do
        it 'returns the iframe src by injecting the observability path' do
          allow(helper).to receive(:params).and_return({ action: '/explore', observability_path: '/foo?bar=foobar' })
          expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/-/#{group.id}/foo?bar=foobar")
        end
      end

      context 'if observability_path is not valid' do
        it 'returns the iframe src by injecting the sanitised observability path' do
          allow(helper).to receive(:params).and_return({
                                                         action: '/explore',
                                                         observability_path:
                                                         "/test?groupId=<script>alert('attack!')</script>"
                                                       })
          expect(helper.observability_iframe_src(group)).to eq(
            "#{observability_url}/-/#{group.id}/test?groupId=alert('attack!')"
          )
        end
      end
    end

    context 'when observability ui is standalone' do
      before do
        stub_env('STANDALONE_OBSERVABILITY_UI', 'true')
      end

      it 'returns the iframe src without group.id for action: dashboards' do
        allow(helper).to receive(:params).and_return({ action: 'dashboards' })
        expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/")
      end

      it 'returns the iframe src without group.id for action: manage' do
        allow(helper).to receive(:params).and_return({ action: 'manage' })
        expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/dashboards")
      end

      it 'returns the iframe src without group.id for action: explore' do
        allow(helper).to receive(:params).and_return({ action: 'explore' })
        expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/explore")
      end

      it 'returns the iframe src without group.id for action: datasources' do
        allow(helper).to receive(:params).and_return({ action: 'datasources' })
        expect(helper.observability_iframe_src(group)).to eq("#{observability_url}/datasources")
      end
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
