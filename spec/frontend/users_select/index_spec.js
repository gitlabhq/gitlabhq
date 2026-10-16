import { escape } from 'lodash-es';
import MockAdapter from 'axios-mock-adapter';
import htmlCeMrSingleAssignees from 'test_fixtures/merge_requests/merge_request_with_single_assignee_feature.html';
import UsersSelect from '~/users_select/index';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  createInputsModelExpectation,
  createUnassignedExpectation,
  createAssignedExpectation,
  createTestContext,
  findDropdownItemsModel,
  findDropdownItem,
  findAssigneesInputsModel,
  getUsersFixtureAt,
  setAssignees,
  toggleDropdown,
  waitForDropdownItems,
} from './test_helper';

describe('~/users_select/index', () => {
  const context = createTestContext({ fixture: htmlCeMrSingleAssignees });

  beforeEach(() => {
    context.setup();
  });

  afterEach(() => {
    context.teardown();
  });

  describe('when opened', () => {
    beforeEach(async () => {
      context.createSubject();

      toggleDropdown();
      await waitForDropdownItems();
    });

    it('shows users', () => {
      expect(findDropdownItemsModel()).toEqual(createUnassignedExpectation());
    });

    describe('when users are selected', () => {
      const selectedUsers = [getUsersFixtureAt(2), getUsersFixtureAt(4)];
      const lastSelected = selectedUsers[selectedUsers.length - 1];
      const expectation = createAssignedExpectation({
        header: 'Assignee',
        assigned: [lastSelected],
      });

      beforeEach(() => {
        selectedUsers.forEach((user) => {
          findDropdownItem(user).click();
        });
      });

      it('shows assignee', () => {
        expect(findDropdownItemsModel()).toEqual(expectation);
      });

      it('updates field', () => {
        expect(findAssigneesInputsModel()).toEqual(createInputsModelExpectation([lastSelected]));
      });
    });
  });

  describe('with preselected user and opened', () => {
    const expectation = createAssignedExpectation({
      header: 'Assignee',
      assigned: [getUsersFixtureAt(0)],
    });

    beforeEach(async () => {
      setAssignees(getUsersFixtureAt(0));

      context.createSubject();

      toggleDropdown();
      await waitForDropdownItems();
    });

    it('shows users', () => {
      expect(findDropdownItemsModel()).toEqual(expectation);
    });

    // Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/325991
    describe('when closed and reopened', () => {
      beforeEach(() => {
        toggleDropdown();
        toggleDropdown();
      });

      it('shows users', () => {
        expect(findDropdownItemsModel()).toEqual(expectation);
      });
    });

    describe('renderApprovalRules', () => {
      const ruleNames = ['simple-name', '"\'<>&', '"><script>alert(1)<script>'];

      it.each(ruleNames)('escapes rule name correctly for %s', (name) => {
        const escapedName = escape(name);

        expect(
          UsersSelect.prototype.renderApprovalRules('reviewer', [{ name }]),
        ).toMatchInterpolatedText(
          `<div class="gl-flex gl-text-sm"> <span class="gl-truncate" title="${escapedName}">${escapedName}</span> </div>`,
        );
      });
    });
  });

  describe('users request caching', () => {
    let mock;
    let instance;
    const usersResponse = [{ id: 1, name: 'Administrator', username: 'root' }];

    const requestUsers = (query, options = {}) =>
      new Promise((resolve) => {
        UsersSelect.prototype.users.call(instance, query, options, resolve);
      });

    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onGet('/-/autocomplete/users.json').reply(HTTP_STATUS_OK, usersResponse);
      instance = {
        usersPath: '/-/autocomplete/users.json',
        buildUrl: (url) => url,
      };
    });

    afterEach(() => {
      mock.restore();
    });

    it('requests users from the API and returns the response', async () => {
      const users = await requestUsers('root');

      expect(mock.history.get).toHaveLength(1);
      expect(users).toEqual(usersResponse);
    });

    it('serves a repeated identical search from the cache without another request', async () => {
      await requestUsers('root');
      const users = await requestUsers('root');

      expect(mock.history.get).toHaveLength(1);
      expect(users).toEqual(usersResponse);
    });

    it('requests again when the search term changes', async () => {
      await requestUsers('root');
      await requestUsers('alex');

      expect(mock.history.get).toHaveLength(2);
    });

    it('caches each search term independently', async () => {
      await requestUsers('root');
      await requestUsers('alex');
      await requestUsers('root');

      expect(mock.history.get).toHaveLength(2);
    });
  });

  describe('XSS', () => {
    const escaped = '&gt;&lt;script&gt;alert(1)&lt;/script&gt;';
    const issuableType = 'merge_request';
    const user = {
      availability: 'not_set',
      can_merge: true,
      name: 'name',
    };
    const selected = true;
    const username = 'username';
    const img = '<img user-avatar />';
    const elsClassName = 'elsclass';

    it.each`
      prop          | val                             | element
      ${'username'} | ${'><script>alert(1)</script>'} | ${'.dropdown-menu-user-username'}
      ${'name'}     | ${'><script>alert(1)</script>'} | ${'.dropdown-menu-user-full-name'}
    `('properly escapes the $prop $val', ({ prop, val, element }) => {
      const u = prop === 'username' ? val : username;
      const n = prop === 'name' ? val : user.name;
      const row = UsersSelect.prototype.renderRow(
        issuableType,
        { ...user, name: n },
        selected,
        u,
        img,
        elsClassName,
      );
      const fragment = document.createRange().createContextualFragment(row);
      const output = fragment.querySelector(element).innerHTML.trim();

      expect(output).toBe(escaped);
    });
  });
});
