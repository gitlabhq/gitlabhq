import { renderGFM } from '~/behaviors/markdown/render_gfm';
import renderMetrics from '~/behaviors/markdown/render_metrics';

jest.mock('~/behaviors/markdown/render_metrics');

describe('renderGFM', () => {
  it('handles a missing element', () => {
    expect(() => {
      renderGFM();
    }).not.toThrow();
  });

  describe('remove_monitor_metrics flag', () => {
    let metricsElement;

    beforeEach(() => {
      window.gon = { features: { removeMonitorMetrics: true } };
      metricsElement = document.createElement('div');
      metricsElement.setAttribute('class', '.js-render-metrics');
    });

    it('renders metrics when the flag is disabled', () => {
      window.gon.features = { features: { removeMonitorMetrics: false } };
      renderGFM(metricsElement);

      expect(renderMetrics).toHaveBeenCalled();
    });

    it('does not render metrics when the flag is enabled', () => {
      renderGFM(metricsElement);

      expect(renderMetrics).not.toHaveBeenCalled();
    });
  });
});
