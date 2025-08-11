import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'spec/test_constants';
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

    expect(findTrigger()).toHaveLength(1);
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

    expect(findTrigger()).toHaveLength(0);
  });
});

describe('anchor link contains special characters', () => {
  global.CSS = {
    escape: (val) => val.replace(/[!"#$%&'()*+,./:;<=>?@[\\\]^`{|}~]/g, '\\$&'),
  };

  const findTarget = () => document.querySelector('.read-more-content');
  const findTrigger = () => document.querySelector('.js-read-more-trigger');
  const findHashTarget = (id) => document.querySelector(`#user-content-${CSS.escape(id)}`);

  const setSpecialCharacterFixture = (hashValue) => {
    setHTMLFixture(`
      <div class="read-more-container" data-read-more-height="50">
        <div class="read-more-content">
          <h2 id="user-content-${hashValue}">${hashValue}</h2>
          <p>Some content here</p>
        </div>
        <button type="button" class="js-read-more-trigger">
          Read more
        </button>
      </div>
    `);
  };

  describe.each`
    hashValue
    ${'日本語'}
    ${'العربية'}
    ${'русский'}
    ${'test:with.special[chars]'}
    ${'test(with)parens'}
    ${'🚀📝✨'}
  `(`when hash contains $hashValue`, ({ hashValue }) => {
    const originalLocation = window.location;

    beforeEach(() => {
      delete window.location;
      window.location = { href: `${TEST_HOST}/foo#${hashValue}`, hash: hashValue };

      setSpecialCharacterFixture(hashValue);
    });

    afterEach(() => {
      window.location = originalLocation;
      resetHTMLFixture();
    });

    it('expands content and removes trigger when hash matches anchor value', () => {
      findHashTarget(hashValue);

      expect(findHashTarget(hashValue)).not.toBe(null);
      expect(findTarget().classList.contains('is-expanded')).toBe(false);

      initReadMore();

      expect(findTarget().classList.contains('is-expanded')).toBe(true);
      expect(findTrigger()).toBe(null);
    });
  });
});
