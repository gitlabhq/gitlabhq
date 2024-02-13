import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initReadMore from '~/read_more';

describe('Read more click-to-expand functionality', () => {
  const findTarget = () => document.querySelector('.read-more-container');
  const findTrigger = () => document.querySelector('.js-read-more-trigger');

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('expands target element', () => {
    beforeEach(() => {
      setHTMLFixture(`
        <p class="read-more-container">Target</p>
        <button type="button" class="js-read-more-trigger">
          <span>Button text</span>
        </button>
      `);
    });

    it('adds "is-expanded" class to target element', () => {
      initReadMore();

      findTrigger().click();

      expect(findTarget().classList.contains('is-expanded')).toEqual(true);
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

      const nestedElement = findTrigger().firstElementChild;
      initReadMore();

      nestedElement.click();
    });

    it('removes the trigger element', () => {
      expect(findTrigger()).toBe(null);
    });
  });

  describe('data-read-more-height defines when to show the read-more button', () => {
    afterEach(() => {
      resetHTMLFixture();
    });

    it('if not set shows button all the time', () => {
      setHTMLFixture(`
        <div class="read-more-container">
          <p class="read-more-content">Occaecat voluptate exercitation aliqua et duis eiusmod mollit esse ea laborum amet consectetur officia culpa anim. Fugiat laboris eu irure deserunt excepteur laboris irure quis. Occaecat nostrud irure do officia ea laborum velit sunt. Aliqua incididunt non deserunt proident magna aliqua sunt laborum laborum eiusmod ullamco. Et elit commodo irure. Labore eu nisi proident.</p>
          <button type="button" class="js-read-more-trigger">
            Button text
          </button>
        </div>
      `);

      initReadMore();

      expect(findTrigger()).not.toBe(null);
    });

    it('if set hides button as threshold is met', () => {
      setHTMLFixture(`
        <div class="read-more-container" data-read-more-height="120">
          <p class="read-more-content read-more-content--has-scrim">Occaecat voluptate exercitation aliqua et duis eiusmod mollit esse ea laborum amet consectetur officia culpa anim. Fugiat laboris eu irure deserunt excepteur laboris irure quis. Occaecat nostrud irure do officia ea laborum velit sunt. Aliqua incididunt non deserunt proident magna aliqua sunt laborum laborum eiusmod ullamco. Et elit commodo irure. Labore eu nisi proident.</p>
          <button type="button" class="js-read-more-trigger">
            Button text
        </button>
        </div>
      `);

      initReadMore();

      expect(findTarget().classList.contains('read-more-content--has-scrim')).toBe(false);
      expect(findTrigger()).toBe(null);
    });
  });
});

describe('data-read-more-height defines when to show the read-more button', () => {
  const findTrigger = () => document.querySelectorAll('.js-read-more-trigger');

  afterEach(() => {
    resetHTMLFixture();
  });

  it('if not set shows button all the time', () => {
    setHTMLFixture(`
      <div class="read-more-container">
        <p class="read-more-content">Occaecat voluptate exercitation aliqua et duis eiusmod mollit esse ea laborum amet consectetur officia culpa anim. Fugiat laboris eu irure deserunt excepteur laboris irure quis. Occaecat nostrud irure do officia ea laborum velit sunt. Aliqua incididunt non deserunt proident magna aliqua sunt laborum laborum eiusmod ullamco. Et elit commodo irure. Labore eu nisi proident.</p>
        <button type="button" class="js-read-more-trigger">
          Button text
        </button>
      </div>
    `);

    initReadMore();

    expect(findTrigger().length).toBe(1);
  });

  it('if set hides button as threshold is met', () => {
    setHTMLFixture(`
      <div class="read-more-container" data-read-more-height="120">
        <p class="read-more-content">Occaecat voluptate exercitation aliqua et duis eiusmod mollit esse ea laborum amet consectetur officia culpa anim. Fugiat laboris eu irure deserunt excepteur laboris irure quis. Occaecat nostrud irure do officia ea laborum velit sunt. Aliqua incididunt non deserunt proident magna aliqua sunt laborum laborum eiusmod ullamco. Et elit commodo irure. Labore eu nisi proident.</p>
        <button type="button" class="js-read-more-trigger">
          Button text
      </button>
      </div>
    `);

    initReadMore();

    expect(findTrigger().length).toBe(0);
  });
});
