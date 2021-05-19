import MockAdapter from 'axios-mock-adapter';
import { memoize, cloneDeep } from 'lodash';
import { getFixture, getJSONFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import UsersSelect from '~/users_select';

// fixtures -------------------------------------------------------------------
const getUserSearchHTML = memoize((fixturePath) => {
  const html = getFixture(fixturePath);
  const parser = new DOMParser();

  const el = parser.parseFromString(html, 'text/html').querySelector('.assignee');

  return el.outerHTML;
});

const getUsersFixture = memoize(() => getJSONFixture('autocomplete/users.json'));

export const getUsersFixtureAt = (idx) => getUsersFixture()[idx];

// test context ---------------------------------------------------------------
export const createTestContext = ({ fixturePath }) => {
  let mock = null;
  let subject = null;

  const setup = () => {
    const rootEl = document.createElement('div');
    rootEl.innerHTML = getUserSearchHTML(fixturePath);
    document.body.appendChild(rootEl);

    mock = new MockAdapter(axios);
    mock.onGet('/-/autocomplete/users.json').reply(200, cloneDeep(getUsersFixture()));
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
export const setAssignees = (...users) => {
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
      show_status: user.show_status.toString(),
      state: user.state,
      username: user.username,
      web_url: user.web_url,
    },
  }));
