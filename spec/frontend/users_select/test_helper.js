import MockAdapter from 'axios-mock-adapter';
import { memoize, cloneDeep } from 'lodash';
import usersFixture from 'test_fixtures/autocomplete/users.json';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import UsersSelect from '~/users_select';

// fixtures -------------------------------------------------------------------
const getUserSearchHTML = memoize((fixture) => {
  const parser = new DOMParser();

  const el = parser
    .parseFromString(fixture, 'text/html')
    .querySelector('[data-testid=merge-request-assignee]');

  return el.outerHTML;
});

const getUsersFixture = () => usersFixture;

export const getUsersFixtureAt = (idx) => getUsersFixture()[idx];

// test context ---------------------------------------------------------------
export const createTestContext = ({ fixture }) => {
  let mock = null;
  let subject = null;

  const setup = () => {
    const rootEl = document.createElement('div');
    rootEl.innerHTML = getUserSearchHTML(fixture);
    document.body.appendChild(rootEl);

    mock = new MockAdapter(axios);
    mock.onGet('/-/autocomplete/users.json').reply(HTTP_STATUS_OK, cloneDeep(getUsersFixture()));
  };

  const teardown = () => {
    mock.restore();
    document.body.innerHTML = '';
    subject = null;
  };

  const createSubject = () => {
    if (subject) {
      throw new Error('test subject is already created');
    }

    subject = new UsersSelect(null);
  };

  return {
    setup,
    teardown,
    createSubject,
  };
};

// finders -------------------------------------------------------------------
export const findAssigneesInputs = () =>
  document.querySelectorAll('input[name="merge_request[assignee_ids][]');
export const findAssigneesInputsModel = () =>
  Array.from(findAssigneesInputs()).map((input) => ({
    value: input.value,
    dataset: { ...input.dataset },
  }));
export const findUserSearchButton = () => document.querySelector('.js-user-search');
export const findDropdownItem = ({ id }) => document.querySelector(`li[data-user-id="${id}"] a`);
export const findDropdownItemsModel = () =>
  Array.from(document.querySelectorAll('.dropdown-content li')).map((el) => {
    if (el.classList.contains('divider')) {
      return {
        type: 'divider',
      };
    }
    if (el.classList.contains('dropdown-header')) {
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
export const setAssignees = (...users) => {
  findAssigneesInputs().forEach((x) => x.remove());

  const container = document.querySelector('.selectbox');

  container.prepend(
    ...users.map((user) => {
      const input = document.createElement('input');
      input.name = 'merge_request[assignee_ids][]';
      input.value = user.id.toString();
      input.dataset.avatarUrl = user.avatar_url;
      input.dataset.name = user.name;
      input.dataset.username = user.username;
      input.dataset.canMerge = user.can_merge;
      return input;
    }),
  );
};
export const toggleDropdown = () => findUserSearchButton().click();
export const waitForDropdownItems = async () => {
  await axios.waitForAll();
  await waitForPromises();
};

// assertion helpers ---------------------------------------------------------
export const createUnassignedExpectation = () => {
  return [
    { type: 'user', userId: '0' },
    { type: 'divider' },
    ...getUsersFixture().map((x) => ({
      type: 'user',
      userId: x.id.toString(),
    })),
  ];
};

export const createAssignedExpectation = ({ header, assigned }) => {
  const assignedIds = new Set(assigned.map((x) => x.id));
  const unassignedIds = getUsersFixture().filter((x) => !assignedIds.has(x.id));

  return [
    { type: 'user', userId: '0' },
    { type: 'divider' },
    { type: 'dropdown-header', text: header },
    ...assigned.map((x) => ({ type: 'user', userId: x.id.toString() })),
    { type: 'divider' },
    ...unassignedIds.map((x) => ({ type: 'user', userId: x.id.toString() })),
  ];
};

export const createInputsModelExpectation = (users) =>
  users.map((user) => ({
    value: user.id.toString(),
    dataset: {
      approved: user.approved.toString(),
      avatar_url: user.avatar_url,
      can_merge: user.can_merge.toString(),
      can_update_merge_request: user.can_update_merge_request.toString(),
      id: user.id.toString(),
      name: user.name,
      meta: user.name,
      show_status: user.show_status.toString(),
      state: user.state,
      locked: user.locked.toString(),
      username: user.username,
      web_url: user.web_url,
    },
  }));
