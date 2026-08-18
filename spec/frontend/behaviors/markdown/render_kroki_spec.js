import { createWrapper } from '@vue/test-utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { renderKroki } from '~/behaviors/markdown/render_kroki';

describe('Kroki diagrams renderer', () => {
  const krokiAlertSelector = '[data-testid="diagram-performance-warning"]';

  // Finders
  const findKrokiAlert = () => createWrapper(document.querySelector(krokiAlertSelector));
  const findAllKrokiAlerts = () => document.querySelectorAll(krokiAlertSelector);
  const findDisplayButton = () => findKrokiAlert().find('.gl-alert-action');
  const findDismissButton = () => findKrokiAlert().find('[aria-label="Dismiss"]');
  const findKrokiImage = () => document.querySelector('img');

  // Helpers
  const renderDiagrams = () => {
    renderKroki([...document.querySelectorAll('.js-render-kroki')]);
  };

  const setKrokiFixture = () => {
    setHTMLFixture(`
      <div>
        <img class="js-render-kroki" hidden>
      </div>
    `);
  };

  beforeEach(() => {
    document.body.dataset.page = '';
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('hidden Kroki diagrams', () => {
    beforeEach(() => {
      setKrokiFixture();

      renderDiagrams();
    });

    it('shows a warning alert', () => {
      expect(findKrokiAlert().exists()).toBe(true);
    });

    it('only creates one alert per Kroki image when processed multiple times', () => {
      renderDiagrams();

      expect(findAllKrokiAlerts()).toHaveLength(1);
    });

    it('shows the Kroki image and removes the warning when clicking Display', () => {
      findDisplayButton().trigger('click');

      expect(findKrokiImage().hasAttribute('hidden')).toBe(false);
      expect(document.querySelector(krokiAlertSelector)).toBe(null);
    });

    it('removes the warning and keeps the image hidden when dismissing the alert', () => {
      findDismissButton().trigger('click');

      expect(document.querySelector(krokiAlertSelector)).toBe(null);
      expect(findKrokiImage().hasAttribute('hidden')).toBe(true);
    });
  });

  describe('on an unrestricted page', () => {
    beforeEach(() => {
      document.body.dataset.page = 'projects:wikis:show';

      setKrokiFixture();

      renderDiagrams();
    });

    it('shows the Kroki image without a warning', () => {
      expect(findKrokiImage().hasAttribute('hidden')).toBe(false);
      expect(document.querySelector(krokiAlertSelector)).toBe(null);
    });
  });
});
