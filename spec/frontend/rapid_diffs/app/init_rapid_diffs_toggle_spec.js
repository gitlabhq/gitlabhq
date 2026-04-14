import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initRapidDiffsToggle } from '~/rapid_diffs/app/init_rapid_diffs_toggle';

jest.mock('~/rapid_diffs/app/rapid_diffs_toggle.vue', () => ({
  name: 'RapidDiffsToggle',
  render(h) {
    return h('div', { attrs: { 'data-rapid-diffs-toggle': 'true' } });
  },
}));

describe('initRapidDiffsToggle', () => {
  const findToggle = () => document.querySelector('[data-rapid-diffs-toggle]');

  afterEach(() => {
    resetHTMLFixture();
    delete window.gon;
  });

  it('returns null when mount element does not exist', () => {
    setHTMLFixture('<div></div>');
    window.gon = { features: { rapidDiffsOnMrShow: true } };

    expect(initRapidDiffsToggle()).toBeNull();
  });

  it('returns null when feature flag is disabled', () => {
    setHTMLFixture(
      '<div id="js-rapid-diffs-toggle"><div class="js-rapid-diffs-toggle-mount"></div></div>',
    );
    window.gon = { features: { rapidDiffsOnMrShow: false } };

    expect(initRapidDiffsToggle()).toBeNull();
  });

  it('mounts the component when element exists and feature flag is enabled', () => {
    setHTMLFixture(
      '<div id="js-rapid-diffs-toggle"><div class="js-rapid-diffs-toggle-mount"></div></div>',
    );
    window.gon = { features: { rapidDiffsOnMrShow: true } };

    const instance = initRapidDiffsToggle();
    expect(instance).not.toBeNull();
    expect(findToggle()).not.toBeNull();
  });
});
