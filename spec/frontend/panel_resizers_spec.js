import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initPanelResizers from '~/panel_resizers';

jest.mock('~/vue_shared/components/panel_width_resizer.vue', () => ({
  name: 'PanelWidthResizerStub',
  props: ['targetEl', 'side', 'hideWhenVisibleEl', 'resizeLabel'],
  render(h) {
    return h('div', {
      attrs: {
        'data-testid': 'panel-width-resizer-stub',
        'data-side': this.side,
        'data-resize-label': this.resizeLabel,
        'data-hide-when-visible-el': this.hideWhenVisibleEl?.id,
      },
    });
  },
}));

describe('initPanelResizers', () => {
  afterEach(() => {
    resetHTMLFixture();
  });

  const findResizerIn = (selector) =>
    document.querySelector(`${selector} [data-testid="panel-width-resizer-stub"]`);
  const findAllResizers = () =>
    document.querySelectorAll('[data-testid="panel-width-resizer-stub"]');

  describe('with the static panel and the dynamic panel portal', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <div class="js-static-panel"></div>
        <div id="contextual-panel-portal"></div>
      `);
      initPanelResizers();
    });

    it('mounts a left-side resizer inside the dynamic panel portal', () => {
      const resizer = findResizerIn('#contextual-panel-portal');

      expect(resizer).not.toBe(null);
      expect(resizer.dataset.side).toBe('left');
      expect(resizer.dataset.resizeLabel).toBe('Resize dynamic panel');
    });

    it('mounts a right-side resizer inside the static panel', () => {
      const resizer = findResizerIn('.js-static-panel');

      expect(resizer).not.toBe(null);
      expect(resizer.dataset.side).toBe('right');
      expect(resizer.dataset.resizeLabel).toBe('Resize static panel');
    });

    it('hides the static panel resizer while the dynamic panel is visible', () => {
      // The dynamic panel owns the shared edge with its own handle
      expect(findResizerIn('.js-static-panel').dataset.hideWhenVisibleEl).toBe(
        'contextual-panel-portal',
      );
    });
  });

  describe('with only the static panel', () => {
    beforeEach(() => {
      setHTMLFixture('<div class="js-static-panel"></div>');
      initPanelResizers();
    });

    it('mounts only the static panel resizer, with no hide target', () => {
      expect(findAllResizers()).toHaveLength(1);

      const resizer = findResizerIn('.js-static-panel');

      expect(resizer.dataset.side).toBe('right');
      expect(resizer.dataset.hideWhenVisibleEl).toBe(undefined);
    });
  });

  describe('with only the dynamic panel portal', () => {
    beforeEach(() => {
      setHTMLFixture('<div id="contextual-panel-portal"></div>');
      initPanelResizers();
    });

    it('mounts only the portal resizer', () => {
      expect(findAllResizers()).toHaveLength(1);
      expect(findResizerIn('#contextual-panel-portal')).not.toBe(null);
    });
  });

  describe('without any panels', () => {
    it('mounts nothing and does not throw', () => {
      setHTMLFixture('<div></div>');

      expect(() => initPanelResizers()).not.toThrow();
      expect(findAllResizers()).toHaveLength(0);
    });
  });
});
