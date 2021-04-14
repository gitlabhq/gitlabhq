import { waitFor } from '@testing-library/dom';
import MockAdapter from 'axios-mock-adapter';
import { cloneDeep } from 'lodash';
import { getFixture, getJSONFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import UsersSelect from '~/users_select';

const getUserSearchHTML = () => {
  const html = getFixture('merge_requests/merge_request_of_current_user.html');
  const parser = new DOMParser();

  const el = parser.parseFromString(html, 'text/html').querySelector('.assignee');

  return el.outerHTML;
};

const USER_SEARCH_HTML = getUserSearchHTML();
const AUTOCOMPLETE_USERS = getJSONFixture('autocomplete/users.json');

describe('~/users_select/index', () => {
  let subject;
  let mock;

  const createSubject = (currentUser = null) => {
    if (subject) {
      throw new Error('test subject is already created');
    }

    subject = new UsersSelect(currentUser);
  };

  // finders -------------------------------------------------------------------
  const findAssigneesInputs = () =>
    document.querySelectorAll('input[name="merge_request[assignee_ids][]');
  const findAssigneesInputsModel = () =>
    Array.from(findAssigneesInputs()).map((input) => ({
      value: input.value,
      dataset: { ...input.dataset },
    }));
  const findUserSearchButton = () => document.querySelector('.js-user-search');
  const findDropdownItem = ({ id }) => document.querySelector(`li[data-user-id="${id}"] a`);
  const findDropdownItemsModel = () =>
    Array.from(document.querySelectorAll('.dropdown-content li')).map((el) => {
      if (el.classList.contains('divider')) {
        return {
          type: 'divider',
        };
      } else if (el.classList.contains('dropdown-header')) {
        return {
          type: 'dropdown-header',
          text: el.textContent,
        };
      }

      return {
        type: 'user',
        userId: el.dataset.userId,
      };
    });

  // arrange/act helpers -------------------------------------------------------
  const setAssignees = (...users) => {
    findAssigneesInputs().forEach((x) => x.remove());

    const container = document.querySelector('.js-sidebar-assignee-data');

    container.prepend(
      ...users.map((user) => {
        const input = document.createElement('input');
        input.name = 'merge_request[assignee_ids][]';
        input.value = user.id.toString();
        input.setAttribute('data-avatar-url', user.avatar_url);
        input.setAttribute('data-name', user.name);
        input.setAttribute('data-username', user.username);
        input.setAttribute('data-can-merge', user.can_merge);
        return input;
      }),
    );
  };
  const toggleDropdown = () => findUserSearchButton().click();
  const waitForDropdownItems = () =>
    waitFor(() => expect(findDropdownItem(AUTOCOMPLETE_USERS[0])).not.toBeNull());

  // assertion helpers ---------------------------------------------------------
  const createUnassignedExpectation = () => {
    return [
      { type: 'user', userId: '0' },
      { type: 'divider' },
      ...AUTOCOMPLETE_USERS.map((x) => ({ type: 'user', userId: x.id.toString() })),
    ];
  };
  const createAssignedExpectation = (...selectedUsers) => {
    const selectedIds = new Set(selectedUsers.map((x) => x.id));
    const unselectedUsers = AUTOCOMPLETE_USERS.filter((x) => !selectedIds.has(x.id));

    return [
      { type: 'user', userId: '0' },
      { type: 'divider' },
      { type: 'dropdown-header', text: 'Assignee(s)' },
      ...selectedUsers.map((x) => ({ type: 'user', userId: x.id.toString() })),
      { type: 'divider' },
      ...unselectedUsers.map((x) => ({ type: 'user', userId: x.id.toString() })),
    ];
  };

  beforeEach(() => {
    const rootEl = document.createElement('div');
    rootEl.innerHTML = USER_SEARCH_HTML;
    document.body.appendChild(rootEl);

    mock = new MockAdapter(axios);
    mock.onGet('/-/autocomplete/users.json').reply(200, cloneDeep(AUTOCOMPLETE_USERS));
  });

  afterEach(() => {
    document.body.innerHTML = '';
    subject = null;
  });

  describe('when opened', () => {
    beforeEach(async () => {
      createSubject();

      toggleDropdown();
      await waitForDropdownItems();
    });

    it('shows users', () => {
      expect(findDropdownItemsModel()).toEqual(createUnassignedExpectation());
    });

    describe('when users are selected', () => {
      const selectedUsers = [AUTOCOMPLETE_USERS[2], AUTOCOMPLETE_USERS[4]];
      const expectation = createAssignedExpectation(...selectedUsers);

      beforeEach(() => {
        selectedUsers.forEach((user) => {
          findDropdownItem(user).click();
        });
      });

      it('shows assignee', () => {
        expect(findDropdownItemsModel()).toEqual(expectation);
      });

      it('shows assignee even after close and open', () => {
        toggleDropdown();
        toggleDropdown();

        expect(findDropdownItemsModel()).toEqual(expectation);
      });

      it('updates field', () => {
        expect(findAssigneesInputsModel()).toEqual(
          selectedUsers.map((user) => ({
            value: user.id.toString(),
            dataset: {
              approved: user.approved.toString(),
              avatar_url: user.avatar_url,
              can_merge: user.can_merge.toString(),
              can_update_merge_request: user.can_update_merge_request.toString(),
              id: user.id.toString(),
              name: user.name,
              show_status: user.show_status.toString(),
              state: user.state,
              username: user.username,
              web_url: user.web_url,
            },
          })),
        );
      });
    });
  });

  describe('with preselected user and opened', () => {
    const expectation = createAssignedExpectation(AUTOCOMPLETE_USERS[0]);

    beforeEach(async () => {
      setAssignees(AUTOCOMPLETE_USERS[0]);

      createSubject();

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
  });
});
