import { loadHTMLFixture, resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import initReadMore from '~/read_more';

describe('Read more click-to-expand functionality', () => {
  const fixtureName = 'projects/overview.html';

  const findTrigger = () => document.querySelector('.js-read-more-trigger');

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('expands target element', () => {
    beforeEach(() => {
      loadHTMLFixture(fixtureName);
    });

    it('adds "is-expanded" class to target element', () => {
      const target = document.querySelector('.read-more-container');
      const trigger = findTrigger();
      initReadMore();

      trigger.click();

      expect(target.classList.contains('is-expanded')).toEqual(true);
    });
  });

  describe('given click on nested element', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <p>Target</p>
        <button type="button" class="js-read-more-trigger">
          <span>Button text</span>
        </button>
      `);

      const trigger = findTrigger();
      const nestedElement = trigger.firstElementChild;
      initReadMore();

      nestedElement.click();
    });

    it('removes the trigger element', async () => {
      expect(findTrigger()).toBe(null);
    });
  });
});
