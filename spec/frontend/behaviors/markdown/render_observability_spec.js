import renderObservability from '~/behaviors/markdown/render_observability';
import * as ColorUtils from '~/lib/utils/color_utils';

describe('Observability iframe renderer', () => {
  const findObservabilityIframes = (theme = 'light') =>
    document.querySelectorAll(`iframe[src="https://observe.gitlab.com/?theme=${theme}&kiosk"]`);

  const renderEmbeddedObservability = () => {
    renderObservability([...document.querySelectorAll('.js-render-observability')]);
    jest.runAllTimers();
  };

  beforeEach(() => {
    document.body.dataset.page = '';
    document.body.innerHTML = '';
  });

  it('renders an observability iframe', () => {
    document.body.innerHTML = `<div class="js-render-observability" data-frame-url="https://observe.gitlab.com/"></div>`;

    expect(findObservabilityIframes()).toHaveLength(0);

    renderEmbeddedObservability();

    expect(findObservabilityIframes()).toHaveLength(1);
  });

  it('renders iframe with dark param when GL has dark theme', () => {
    document.body.innerHTML = `<div class="js-render-observability" data-frame-url="https://observe.gitlab.com/"></div>`;
    jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => true);

    expect(findObservabilityIframes('dark')).toHaveLength(0);

    renderEmbeddedObservability();

    expect(findObservabilityIframes('dark')).toHaveLength(1);
  });
});
