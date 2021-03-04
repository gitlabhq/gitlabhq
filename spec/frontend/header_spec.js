import $ from 'jquery';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import initTodoToggle, { initNavUserDropdownTracking } from '~/header';

describe('Header', () => {
  describe('Todos notification', () => {
    const todosPendingCount = '.js-todos-count';
    const fixtureTemplate = 'issues/open-issue.html';

    function isTodosCountHidden() {
      return $(todosPendingCount).hasClass('hidden');
    }

    function triggerToggle(newCount) {
      $(document).trigger('todo:toggle', newCount);
    }

    beforeEach(() => {
      initTodoToggle();
      loadFixtures(fixtureTemplate);
    });

    it('should update todos-count after receiving the todo:toggle event', () => {
      triggerToggle(5);

      expect($(todosPendingCount).text()).toEqual('5');
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
        expect($(todosPendingCount).text()).toEqual('99+');
      });
    });
  });

  describe('Track user dropdown open', () => {
    let trackingSpy;

    beforeEach(() => {
      setFixtures(`
      <li class="js-nav-user-dropdown">
        <a class="js-buy-pipeline-minutes-link" data-track-event="click_buy_ci_minutes" data-track-label="free" data-track-property="user_dropdown">Buy Pipeline minutes</a>
        <a class="js-upgrade-plan-link" data-track-event="click_upgrade_link" data-track-label="free" data-track-property="user_dropdown">Upgrade</a>
      </li>`);

      trackingSpy = mockTracking('_category_', $('.js-nav-user-dropdown').element, jest.spyOn);
      document.body.dataset.page = 'some:page';

      initNavUserDropdownTracking();
    });

    afterEach(() => {
      unmockTracking();
    });

    it('sends a tracking event when the dropdown is opened and contains Buy Pipeline minutes link', () => {
      $('.js-nav-user-dropdown').trigger('shown.bs.dropdown');

      expect(trackingSpy).toHaveBeenCalledWith('some:page', 'show_buy_ci_minutes', {
        label: 'free',
        property: 'user_dropdown',
      });
    });

    it('sends a tracking event when the dropdown is opened and contains Upgrade link', () => {
      $('.js-nav-user-dropdown').trigger('shown.bs.dropdown');

      expect(trackingSpy).toHaveBeenCalledWith('some:page', 'show_upgrade_link', {
        label: 'free',
        property: 'user_dropdown',
      });
    });
  });
});
