/* eslint-disable no-unused-expressions, consistent-return, no-param-reassign, default-case, no-return-assign */

import $ from 'jquery';
import AxiosMockAdapter from 'axios-mock-adapter';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import initSearchAutocomplete from '~/search_autocomplete';
import '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';

describe('Search autocomplete dropdown', () => {
  let widget = null;

  const userName = 'root';
  const userId = 1;
  const dashboardIssuesPath = '/dashboard/issues';
  const dashboardMRsPath = '/dashboard/merge_requests';
  const projectIssuesPath = '/gitlab-org/gitlab-foss/issues';
  const projectMRsPath = '/gitlab-org/gitlab-foss/-/merge_requests';
  const groupIssuesPath = '/groups/gitlab-org/-/issues';
  const groupMRsPath = '/groups/gitlab-org/-/merge_requests';
  const autocompletePath = '/search/autocomplete';
  const projectName = 'GitLab Community Edition';
  const groupName = 'Gitlab Org';

  const removeBodyAttributes = () => {
    const $body = $('body');

    $body.removeAttr('data-page');
    $body.removeAttr('data-project');
    $body.removeAttr('data-group');
  };

  // Add required attributes to body before starting the test.
  // section would be dashboard|group|project
  const addBodyAttributes = section => {
    if (section == null) {
      section = 'dashboard';
    }

    const $body = $('body');
    removeBodyAttributes();
    switch (section) {
      case 'dashboard':
        return $body.attr('data-page', 'root:index');
      case 'group':
        $body.attr('data-page', 'groups:show');
        return $body.data('group', 'gitlab-org');
      case 'project':
        $body.attr('data-page', 'projects:show');
        return $body.data('project', 'gitlab-ce');
    }
  };

  const disableProjectIssues = () => {
    document.querySelector('.js-search-project-options').setAttribute('data-issues-disabled', true);
  };

  // Mock `gl` object in window for dashboard specific page. App code will need it.
  const mockDashboardOptions = () => {
    window.gl || (window.gl = {});
    return (window.gl.dashboardOptions = {
      issuesPath: dashboardIssuesPath,
      mrPath: dashboardMRsPath,
    });
  };

  // Mock `gl` object in window for project specific page. App code will need it.
  const mockProjectOptions = () => {
    window.gl || (window.gl = {});
    return (window.gl.projectOptions = {
      'gitlab-ce': {
        issuesPath: projectIssuesPath,
        mrPath: projectMRsPath,
        projectName,
      },
    });
  };

  const mockGroupOptions = () => {
    window.gl || (window.gl = {});
    return (window.gl.groupOptions = {
      'gitlab-org': {
        issuesPath: groupIssuesPath,
        mrPath: groupMRsPath,
        projectName: groupName,
      },
    });
  };

  const assertLinks = (list, issuesPath, mrsPath) => {
    if (issuesPath) {
      const issuesAssignedToMeLink = `a[href="${issuesPath}/?assignee_username=${userName}"]`;
      const issuesIHaveCreatedLink = `a[href="${issuesPath}/?author_username=${userName}"]`;

      expect(list.find(issuesAssignedToMeLink).length).toBe(1);
      expect(list.find(issuesAssignedToMeLink).text()).toBe('Issues assigned to me');
      expect(list.find(issuesIHaveCreatedLink).length).toBe(1);
      expect(list.find(issuesIHaveCreatedLink).text()).toBe("Issues I've created");
    }
    const mrsAssignedToMeLink = `a[href="${mrsPath}/?assignee_username=${userName}"]`;
    const mrsIHaveCreatedLink = `a[href="${mrsPath}/?author_username=${userName}"]`;

    expect(list.find(mrsAssignedToMeLink).length).toBe(1);
    expect(list.find(mrsAssignedToMeLink).text()).toBe('Merge requests assigned to me');
    expect(list.find(mrsIHaveCreatedLink).length).toBe(1);
    expect(list.find(mrsIHaveCreatedLink).text()).toBe("Merge requests I've created");
  };

  preloadFixtures('static/search_autocomplete.html');
  beforeEach(() => {
    loadFixtures('static/search_autocomplete.html');

    window.gon = {};
    window.gon.current_user_id = userId;
    window.gon.current_username = userName;
    window.gl = window.gl || (window.gl = {});

    return (widget = initSearchAutocomplete({ autocompletePath }));
  });

  afterEach(() => {
    // Undo what we did to the shared <body>
    removeBodyAttributes();
    window.gon = {};
  });

  it('should show Dashboard specific dropdown menu', () => {
    addBodyAttributes();
    mockDashboardOptions();
    widget.searchInput.triggerHandler('focus');
    const list = widget.wrap.find('.dropdown-menu').find('ul');
    return assertLinks(list, dashboardIssuesPath, dashboardMRsPath);
  });

  it('should show Group specific dropdown menu', () => {
    addBodyAttributes('group');
    mockGroupOptions();
    widget.searchInput.triggerHandler('focus');
    const list = widget.wrap.find('.dropdown-menu').find('ul');
    return assertLinks(list, groupIssuesPath, groupMRsPath);
  });

  it('should show Project specific dropdown menu', () => {
    addBodyAttributes('project');
    mockProjectOptions();
    widget.searchInput.triggerHandler('focus');
    const list = widget.wrap.find('.dropdown-menu').find('ul');
    return assertLinks(list, projectIssuesPath, projectMRsPath);
  });

  it('should show only Project mergeRequest dropdown menu items when project issues are disabled', () => {
    addBodyAttributes('project');
    disableProjectIssues();
    mockProjectOptions();
    widget.searchInput.triggerHandler('focus');
    const list = widget.wrap.find('.dropdown-menu').find('ul');
    assertLinks(list, null, projectMRsPath);
  });

  it('should not show category related menu if there is text in the input', () => {
    addBodyAttributes('project');
    mockProjectOptions();
    widget.searchInput.val('help');
    widget.searchInput.triggerHandler('focus');
    const list = widget.wrap.find('.dropdown-menu').find('ul');
    const link = `a[href='${projectIssuesPath}/?assignee_username=${userName}']`;

    expect(list.find(link).length).toBe(0);
  });

  it('should not submit the search form when selecting an autocomplete row with the keyboard', () => {
    const ENTER = 13;
    const DOWN = 40;
    addBodyAttributes();
    mockDashboardOptions(true);
    const submitSpy = jest.spyOn(document.querySelector('form'), 'submit');
    widget.searchInput.triggerHandler('focus');
    widget.wrap.trigger($.Event('keydown', { which: DOWN }));
    const enterKeyEvent = $.Event('keydown', { which: ENTER });
    widget.searchInput.trigger(enterKeyEvent);

    // This does not currently catch failing behavior. For security reasons,
    // browsers will not trigger default behavior (form submit, in this
    // example) on JavaScript-created keypresses.
    expect(submitSpy).not.toHaveBeenCalled();
  });

  describe('show autocomplete results', () => {
    beforeEach(() => {
      widget.enableAutocomplete();

      const axiosMock = new AxiosMockAdapter(axios);
      const autocompleteUrl = new RegExp(autocompletePath);

      axiosMock.onGet(autocompleteUrl).reply(200, [
        {
          category: 'Projects',
          id: 1,
          value: 'Gitlab Test',
          label: 'Gitlab Org / Gitlab Test',
          url: '/gitlab-org/gitlab-test',
          avatar_url: '',
        },
        {
          category: 'Groups',
          id: 1,
          value: 'Gitlab Org',
          label: 'Gitlab Org',
          url: '/gitlab-org',
          avatar_url: '',
        },
      ]);
    });

    function triggerAutocomplete() {
      return new Promise(resolve => {
        const dropdown = widget.searchInput.data('deprecatedJQueryDropdown');
        const filterCallback = dropdown.filter.options.callback;
        dropdown.filter.options.callback = jest.fn(data => {
          filterCallback(data);

          resolve();
        });

        widget.searchInput.val('Gitlab');
        widget.searchInput.triggerHandler('input');
      });
    }

    it('suggest Projects', done => {
      // eslint-disable-next-line promise/catch-or-return
      triggerAutocomplete().finally(() => {
        const list = widget.wrap.find('.dropdown-menu').find('ul');
        const link = "a[href$='/gitlab-org/gitlab-test']";

        expect(list.find(link).length).toBe(1);

        done();
      });

      // Make sure jest properly acknowledge the `done` invocation
      jest.runOnlyPendingTimers();
    });

    it('suggest Groups', done => {
      // eslint-disable-next-line promise/catch-or-return
      triggerAutocomplete().finally(() => {
        const list = widget.wrap.find('.dropdown-menu').find('ul');
        const link = "a[href$='/gitlab-org']";

        expect(list.find(link).length).toBe(1);

        done();
      });

      // Make sure jest properly acknowledge the `done` invocation
      jest.runOnlyPendingTimers();
    });
  });

  describe('disableAutocomplete', () => {
    beforeEach(() => {
      widget.enableAutocomplete();
    });

    it('should close the Dropdown', () => {
      const toggleSpy = jest.spyOn(widget.dropdownToggle, 'dropdown');

      widget.dropdown.addClass('show');
      widget.disableAutocomplete();

      expect(toggleSpy).toHaveBeenCalledWith('toggle');
    });
  });

  describe('enableAutocomplete', () => {
    let toggleSpy;
    let trackingSpy;

    beforeEach(() => {
      toggleSpy = jest.spyOn(widget.dropdownToggle, 'dropdown');
      trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
      document.body.dataset.page = 'some:page'; // default tracking for category
    });

    afterEach(() => {
      unmockTracking();
    });

    it('should open the Dropdown', () => {
      widget.enableAutocomplete();

      expect(toggleSpy).toHaveBeenCalledWith('toggle');
    });

    it('should track the opening', () => {
      widget.enableAutocomplete();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_search_bar', {
        label: 'main_navigation',
        property: 'navigation',
      });
    });
  });
});
