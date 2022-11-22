import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import SidebarMoveIssue from '~/sidebar/lib/sidebar_move_issue';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import { GitLabDropdown } from '~/deprecated_jquery_dropdown/gl_dropdown';
import Mock from '../mock_data';

jest.mock('~/flash');

describe('SidebarMoveIssue', () => {
  let mock;
  const test = {};

  beforeEach(() => {
    mock = new MockAdapter(axios);
    const mockData = Mock.responseMap.GET['/autocomplete/projects?project_id=15'];
    mock.onGet('/autocomplete/projects?project_id=15').reply(200, mockData);
    test.mediator = new SidebarMediator(Mock.mediator);
    test.$content = $(`
      <div class="dropdown">
        <div class="js-toggle"></div>
        <div class="dropdown-menu">
          <div class="dropdown-content"></div>
        </div>
        <div class="js-confirm-button"></div>
      </div>
    `);
    test.$toggleButton = test.$content.find('.js-toggle');
    test.$confirmButton = test.$content.find('.js-confirm-button');

    test.sidebarMoveIssue = new SidebarMoveIssue(
      test.mediator,
      test.$toggleButton,
      test.$confirmButton,
    );
    test.sidebarMoveIssue.init();
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;

    test.sidebarMoveIssue.destroy();
    mock.restore();
  });

  describe('init', () => {
    it('should initialize the dropdown and listeners', () => {
      jest.spyOn(test.sidebarMoveIssue, 'initDropdown').mockImplementation(() => {});
      jest.spyOn(test.sidebarMoveIssue, 'addEventListeners').mockImplementation(() => {});

      test.sidebarMoveIssue.init();

      expect(test.sidebarMoveIssue.initDropdown).toHaveBeenCalled();
      expect(test.sidebarMoveIssue.addEventListeners).toHaveBeenCalled();
    });
  });

  describe('destroy', () => {
    it('should remove the listeners', () => {
      jest.spyOn(test.sidebarMoveIssue, 'removeEventListeners').mockImplementation(() => {});

      test.sidebarMoveIssue.destroy();

      expect(test.sidebarMoveIssue.removeEventListeners).toHaveBeenCalled();
    });
  });

  describe('initDropdown', () => {
    it('should initialize the deprecatedJQueryDropdown', () => {
      test.sidebarMoveIssue.initDropdown();

      expect(test.sidebarMoveIssue.$dropdownToggle.data('deprecatedJQueryDropdown')).toBeInstanceOf(
        GitLabDropdown,
      );
    });

    it('escapes html from project name', async () => {
      test.$toggleButton.dropdown('toggle');

      await waitForPromises();

      expect(test.$content.find('.js-move-issue-dropdown-item')[1].innerHTML.trim()).toEqual(
        '&lt;img src=x onerror=alert(document.domain)&gt; foo / bar',
      );
    });
  });

  describe('onConfirmClicked', () => {
    it('should move the issue with valid project ID', () => {
      jest.spyOn(test.mediator, 'moveIssue').mockReturnValue(Promise.resolve());
      test.mediator.setMoveToProjectId(7);

      test.sidebarMoveIssue.onConfirmClicked();

      expect(test.mediator.moveIssue).toHaveBeenCalled();
      expect(test.$confirmButton.prop('disabled')).toBe(true);
      expect(test.$confirmButton.hasClass('is-loading')).toBe(true);
    });

    it('should remove loading state from confirm button on failure', async () => {
      jest.spyOn(test.mediator, 'moveIssue').mockReturnValue(Promise.reject());
      test.mediator.setMoveToProjectId(7);

      test.sidebarMoveIssue.onConfirmClicked();

      expect(test.mediator.moveIssue).toHaveBeenCalled();

      // Wait for the move issue request to fail
      await waitForPromises();

      expect(createAlert).toHaveBeenCalled();
      expect(test.$confirmButton.prop('disabled')).toBe(false);
      expect(test.$confirmButton.hasClass('is-loading')).toBe(false);
    });

    it('should not move the issue with id=0', () => {
      jest.spyOn(test.mediator, 'moveIssue').mockImplementation(() => {});
      test.mediator.setMoveToProjectId(0);

      test.sidebarMoveIssue.onConfirmClicked();

      expect(test.mediator.moveIssue).not.toHaveBeenCalled();
    });
  });

  it('should set moveToProjectId on dropdown item "No project" click', async () => {
    jest.spyOn(test.mediator, 'setMoveToProjectId').mockImplementation(() => {});

    // Open the dropdown
    test.$toggleButton.dropdown('toggle');

    // Wait for the autocomplete request to finish
    await waitForPromises();

    test.$content.find('.js-move-issue-dropdown-item').eq(0).trigger('click');

    expect(test.mediator.setMoveToProjectId).toHaveBeenCalledWith(0);
    expect(test.$confirmButton.prop('disabled')).toBe(true);
  });

  it('should set moveToProjectId on dropdown item click', async () => {
    jest.spyOn(test.mediator, 'setMoveToProjectId').mockImplementation(() => {});

    // Open the dropdown
    test.$toggleButton.dropdown('toggle');

    // Wait for the autocomplete request to finish
    await waitForPromises();

    test.$content.find('.js-move-issue-dropdown-item').eq(1).trigger('click');

    expect(test.mediator.setMoveToProjectId).toHaveBeenCalledWith(20);
    expect(test.$confirmButton.attr('disabled')).toBe(undefined);
  });
});
