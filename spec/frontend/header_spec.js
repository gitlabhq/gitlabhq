import htmlOpenIssue from 'test_fixtures/issues/open-issue.html';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import initTodoToggle, { initNavUserDropdownTracking } from '~/header';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('Header', () => {
  describe('Todos notification', () => {
    const todosPendingCount = '.js-todos-count';

    function isTodosCountHidden() {
      return document.querySelector(todosPendingCount).classList.contains('hidden');
    }

    function triggerToggle(newCount) {
      const event = new CustomEvent('todo:toggle', {
        detail: {
          count: newCount,
        },
      });

      document.dispatchEvent(event);
    }

    beforeEach(() => {
      initTodoToggle();
      setHTMLFixture(htmlOpenIssue);
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('should update todos-count after receiving the todo:toggle event', () => {
      triggerToggle(5);

      expect(document.querySelector(todosPendingCount).textContent).toEqual('5');
    });

    it('should hide todos-count when it is 0', () => {
      triggerToggle(0);

      expect(isTodosCountHidden()).toEqual(true);
    });

    it('should show todos-count when it is more than 0', () => {
      triggerToggle(10);

      expect(isTodosCountHidden()).toEqual(false);
    });

    describe('when todos-count is 1000', () => {
      beforeEach(() => {
        triggerToggle(1000);
      });

      it('should show todos-count', () => {
        expect(isTodosCountHidden()).toEqual(false);
      });

      it('should show 99+ for todos-count', () => {
        expect(document.querySelector(todosPendingCount).textContent).toEqual('99+');
      });
    });
  });

  describe('Track user dropdown open', () => {
    let trackingSpy;

    beforeEach(() => {
      setHTMLFixture(`
      <li class="js-nav-user-dropdown">
        <a class="js-buy-pipeline-minutes-link" data-track-action="click_buy_ci_minutes" data-track-label="free" data-track-property="user_dropdown">Buy Pipeline minutes</a>
      </li>`);

      trackingSpy = mockTracking(
        '_category_',
        document.querySelector('.js-nav-user-dropdown').element,
        jest.spyOn,
      );
      document.body.dataset.page = 'some:page';

      initNavUserDropdownTracking();
    });

    afterEach(() => {
      unmockTracking();
      resetHTMLFixture();
    });

    it('sends a tracking event when the dropdown is opened and contains Buy Pipeline minutes link', () => {
      const event = new CustomEvent('shown.bs.dropdown');
      document.querySelector('.js-nav-user-dropdown').dispatchEvent(event);

      expect(trackingSpy).toHaveBeenCalledWith('some:page', 'show_buy_ci_minutes', {
        label: 'free',
        property: 'user_dropdown',
      });
    });
  });
});
