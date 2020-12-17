import { mount, createLocalVue, createWrapper } from '@vue/test-utils';
import Vuex from 'vuex';
import {
  getByText as getByTextHelper,
  getByTestId as getByTestIdHelper,
  within,
} from '@testing-library/dom';
import { GlBadge, GlTable } from '@gitlab/ui';
import MembersTable from '~/members/components/table/members_table.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import MemberSource from '~/members/components/table/member_source.vue';
import ExpiresAt from '~/members/components/table/expires_at.vue';
import CreatedAt from '~/members/components/table/created_at.vue';
import RoleDropdown from '~/members/components/table/role_dropdown.vue';
import ExpirationDatepicker from '~/members/components/table/expiration_datepicker.vue';
import MemberActionButtons from '~/members/components/table/member_action_buttons.vue';
import * as initUserPopovers from '~/user_popovers';
import { member as memberMock, invite, accessRequest } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MembersTable', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state: {
        members: [],
        tableFields: [],
        tableAttrs: {
          table: { 'data-qa-selector': 'members_list' },
          tr: { 'data-qa-selector': 'member_row' },
        },
        sourceId: 1,
        currentUserId: 1,
        ...state,
      },
    });
  };

  const createComponent = state => {
    wrapper = mount(MembersTable, {
      localVue,
      store: createStore(state),
      stubs: [
        'member-avatar',
        'member-source',
        'expires-at',
        'created-at',
        'member-action-buttons',
        'role-dropdown',
        'remove-group-link-modal',
        'expiration-datepicker',
      ],
    });
  };

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  const getByTestId = (id, options) =>
    createWrapper(getByTestIdHelper(wrapper.element, id, options));

  const findTable = () => wrapper.find(GlTable);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('fields', () => {
    const directMember = {
      ...memberMock,
      source: { ...memberMock.source, id: 1 },
    };

    const memberCanUpdate = {
      ...directMember,
      canUpdate: true,
    };

    it.each`
      field           | label               | member             | expectedComponent
      ${'account'}    | ${'Account'}        | ${memberMock}      | ${MemberAvatar}
      ${'source'}     | ${'Source'}         | ${memberMock}      | ${MemberSource}
      ${'granted'}    | ${'Access granted'} | ${memberMock}      | ${CreatedAt}
      ${'invited'}    | ${'Invited'}        | ${invite}          | ${CreatedAt}
      ${'requested'}  | ${'Requested'}      | ${accessRequest}   | ${CreatedAt}
      ${'expires'}    | ${'Access expires'} | ${memberMock}      | ${ExpiresAt}
      ${'maxRole'}    | ${'Max role'}       | ${memberCanUpdate} | ${RoleDropdown}
      ${'expiration'} | ${'Expiration'}     | ${memberMock}      | ${ExpirationDatepicker}
    `('renders the $label field', ({ field, label, member, expectedComponent }) => {
      createComponent({
        members: [member],
        tableFields: [field],
      });

      expect(getByText(label, { selector: '[role="columnheader"]' }).exists()).toBe(true);

      if (expectedComponent) {
        expect(
          wrapper
            .find(`[data-label="${label}"][role="cell"]`)
            .find(expectedComponent)
            .exists(),
        ).toBe(true);
      }
    });

    describe('"Actions" field', () => {
      it('renders "Actions" field for screen readers', () => {
        createComponent({ members: [memberCanUpdate], tableFields: ['actions'] });

        const actionField = getByTestId('col-actions');

        expect(actionField.exists()).toBe(true);
        expect(actionField.classes('gl-sr-only')).toBe(true);
        expect(
          wrapper
            .find(`[data-label="Actions"][role="cell"]`)
            .find(MemberActionButtons)
            .exists(),
        ).toBe(true);
      });

      describe('when user is not logged in', () => {
        it('does not render the "Actions" field', () => {
          createComponent({ currentUserId: null, tableFields: ['actions'] });

          expect(within(wrapper.element).queryByTestId('col-actions')).toBe(null);
        });
      });

      const memberCanRemove = {
        ...directMember,
        canRemove: true,
      };

      describe.each`
        permission     | members
        ${'canUpdate'} | ${[memberCanUpdate]}
        ${'canRemove'} | ${[memberCanRemove]}
        ${'canResend'} | ${[invite]}
      `('when one of the members has $permission permissions', ({ members }) => {
        it('renders the "Actions" field', () => {
          createComponent({ members, tableFields: ['actions'] });

          expect(getByTestId('col-actions').exists()).toBe(true);
        });
      });

      describe.each`
        permission     | members
        ${'canUpdate'} | ${[memberMock]}
        ${'canRemove'} | ${[memberMock]}
        ${'canResend'} | ${[{ ...invite, invite: { ...invite.invite, canResend: false } }]}
      `('when none of the members have $permission permissions', ({ members }) => {
        it('does not render the "Actions" field', () => {
          createComponent({ members, tableFields: ['actions'] });

          expect(within(wrapper.element).queryByTestId('col-actions')).toBe(null);
        });
      });
    });
  });

  describe('when `members` is an empty array', () => {
    it('displays a "No members found" message', () => {
      createComponent();

      expect(getByText('No members found').exists()).toBe(true);
    });
  });

  describe('when member can not be updated', () => {
    it('renders badge in "Max role" field', () => {
      createComponent({ members: [memberMock], tableFields: ['maxRole'] });

      expect(
        wrapper
          .find(`[data-label="Max role"][role="cell"]`)
          .find(GlBadge)
          .text(),
      ).toBe(memberMock.accessLevel.stringValue);
    });
  });

  it('initializes user popovers when mounted', () => {
    const initUserPopoversMock = jest.spyOn(initUserPopovers, 'default');

    createComponent();

    expect(initUserPopoversMock).toHaveBeenCalled();
  });

  it('adds QA selector to table', () => {
    createComponent();

    expect(findTable().attributes('data-qa-selector')).toBe('members_list');
  });

  it('adds QA selector to table row', () => {
    createComponent();

    expect(
      findTable()
        .find('tbody tr')
        .attributes('data-qa-selector'),
    ).toBe('member_row');
  });
});
