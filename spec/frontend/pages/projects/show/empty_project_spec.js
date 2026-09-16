import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import EmptyProject from '~/pages/projects/show/empty_project';

// jsdom has no CSS.escape, which GlTabsBehavior uses to read the location hash.
global.CSS = {
  escape: (val) => val,
};

describe('EmptyProject', () => {
  const tabsNav = (className) => `
    <ul class="${className}">
      <li class="nav-item"><a href="#" class="gl-tab-nav-item active" aria-controls="one">One</a></li>
      <li class="nav-item"><a href="#" class="gl-tab-nav-item" aria-controls="two">Two</a></li>
    </ul>
    <div class="tab-content">
      <div id="one" class="tab-pane active"></div>
      <div id="two" class="tab-pane"></div>
    </div>
  `;

  const findTabs = (className) => document.querySelectorAll(`.${className} [role="tab"]`);

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when both tab navs are rendered', () => {
    beforeEach(() => {
      setHTMLFixture(tabsNav('js-configure-git-tabs') + tabsNav('js-empty-project-tabs'));
      // eslint-disable-next-line no-new
      new EmptyProject();
    });

    it('activates tab behavior on both navs', () => {
      expect(findTabs('js-configure-git-tabs')[0].getAttribute('aria-selected')).toBe('true');
      expect(findTabs('js-empty-project-tabs')[0].getAttribute('aria-selected')).toBe('true');
    });
  });

  describe('when the protocol tabs are not rendered, for example when SSH is disabled', () => {
    beforeEach(() => {
      setHTMLFixture(tabsNav('js-configure-git-tabs'));
    });

    it('does not throw and still activates the Git config tabs', () => {
      expect(() => new EmptyProject()).not.toThrow();
      expect(findTabs('js-configure-git-tabs')[0].getAttribute('aria-selected')).toBe('true');
    });
  });

  describe('when the user cannot push and no tabs are rendered', () => {
    beforeEach(() => {
      setHTMLFixture('<div id="js-project-show-empty-page"></div>');
    });

    it('does not throw', () => {
      expect(() => new EmptyProject()).not.toThrow();
    });
  });
});
