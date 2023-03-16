import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import highlightCurrentUser from '~/behaviors/markdown/highlight_current_user';

describe('highlightCurrentUser', () => {
  let rootElement;
  let elements;

  beforeEach(() => {
    setHTMLFixture(`
      <div id="dummy-root-element">
        <div data-user="1">@first</div>
        <div data-user="2">@second</div>
      </div>
    `);
    rootElement = document.getElementById('dummy-root-element');
    elements = rootElement.querySelectorAll('[data-user]');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('without current user', () => {
    beforeEach(() => {
      window.gon.current_user_id = null;
    });

    it('does not highlight the user', () => {
      const initialHtml = rootElement.outerHTML;

      highlightCurrentUser(elements);

      expect(rootElement.outerHTML).toBe(initialHtml);
    });
  });

  describe('with current user', () => {
    beforeEach(() => {
      window.gon.current_user_id = 2;
    });

    it('highlights current user', () => {
      highlightCurrentUser(elements);

      expect(elements.length).toBe(2);
      expect(elements[0]).not.toHaveClass('current-user');
      expect(elements[1]).toHaveClass('current-user');
    });
  });
});
