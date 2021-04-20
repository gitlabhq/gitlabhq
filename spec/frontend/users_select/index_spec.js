import { waitFor } from '@testing-library/dom';
import MockAdapter from 'axios-mock-adapter';
import { cloneDeep } from 'lodash';
import { getJSONFixture } from 'helpers/fixtures';
import axios from '~/lib/utils/axios_utils';
import UsersSelect from '~/users_select';

// TODO: generate this from a fixture that guarantees the same output in CE and EE [(see issue)][1].
// Hardcoding this HTML temproarily fixes a FOSS ~"master::broken" [(see issue)][2].
// [1]: https://gitlab.com/gitlab-org/gitlab/-/issues/327809
// [2]: https://gitlab.com/gitlab-org/gitlab/-/issues/327805
const getUserSearchHTML = () => `
<div class="js-sidebar-assignee-data selectbox hide-collapsed">
<input type="hidden" name="merge_request[assignee_ids][]" value="0">
<div class="dropdown js-sidebar-assignee-dropdown">
<button class="dropdown-menu-toggle js-user-search js-author-search js-multiselect js-save-user-data js-invite-members-track" type="button" data-first-user="frontend-fixtures" data-current-user="true" data-iid="1" data-issuable-type="merge_request" data-project-id="1" data-author-id="1" data-field-name="merge_request[assignee_ids][]" data-issue-update="http://test.host/frontend-fixtures/merge-requests-project/-/merge_requests/1.json" data-ability-name="merge_request" data-null-user="true" data-display="static" data-multi-select="true" data-dropdown-title="Select assignee(s)" data-dropdown-header="Assignee(s)" data-track-event="show_invite_members" data-toggle="dropdown"><span class="dropdown-toggle-text ">Select assignee(s)</span><svg class="s16 dropdown-menu-toggle-icon gl-top-3" data-testid="chevron-down-icon"><use xlink:href="http://test.host/assets/icons-16c30bec0d8a57f0a33e6f6215c6aff7a6ec5e4a7e6b7de733a6b648541a336a.svg#chevron-down"></use></svg></button><div class="dropdown-menu dropdown-select dropdown-menu-user dropdown-menu-selectable dropdown-menu-author dropdown-extended-height">
<div class="dropdown-title gl-display-flex">
<span class="gl-ml-auto">Assign to</span><button class="dropdown-title-button dropdown-menu-close gl-ml-auto" aria-label="Close" type="button"><svg class="s16 dropdown-menu-close-icon" data-testid="close-icon"><use xlink:href="http://test.host/assets/icons-16c30bec0d8a57f0a33e6f6215c6aff7a6ec5e4a7e6b7de733a6b648541a336a.svg#close"></use></svg></button>
</div>
<div class="dropdown-input">
<input type="search" id="" data-qa-selector="dropdown_input_field" class="dropdown-input-field" placeholder="Search users" autocomplete="off"><svg class="s16 dropdown-input-search" data-testid="search-icon"><use xlink:href="http://test.host/assets/icons-16c30bec0d8a57f0a33e6f6215c6aff7a6ec5e4a7e6b7de733a6b648541a336a.svg#search"></use></svg><svg class="s16 dropdown-input-clear js-dropdown-input-clear" data-testid="close-icon"><use xlink:href="http://test.host/assets/icons-16c30bec0d8a57f0a33e6f6215c6aff7a6ec5e4a7e6b7de733a6b648541a336a.svg#close"></use></svg>
</div>
<div data-qa-selector="dropdown_list_content" class="dropdown-content "></div>
<div class="dropdown-footer">
<ul class="dropdown-footer-list">
<li>
<div class="js-invite-members-trigger" data-display-text="Invite Members" data-event="click_invite_members" data-label="edit_assignee" data-trigger-element="anchor"></div>
</li>
</ul>
</div>
<div class="dropdown-loading"><div class="gl-spinner-container"><span class="gl-spinner gl-spinner-orange gl-spinner-md gl-mt-7" aria-label="Loading"></span></div></div>
</div>
</div>
</div>
`;

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
