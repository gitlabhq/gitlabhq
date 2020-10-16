import { mount, createLocalVue, createWrapper } from '@vue/test-utils';
import Vuex from 'vuex';
import {
  getByText as getByTextHelper,
  getByTestId as getByTestIdHelper,
} from '@testing-library/dom';
import { GlBadge } from '@gitlab/ui';
import MembersTable from '~/vue_shared/components/members/table/members_table.vue';
import MemberAvatar from '~/vue_shared/components/members/table/member_avatar.vue';
import MemberSource from '~/vue_shared/components/members/table/member_source.vue';
import ExpiresAt from '~/vue_shared/components/members/table/expires_at.vue';
import CreatedAt from '~/vue_shared/components/members/table/created_at.vue';
import RoleDropdown from '~/vue_shared/components/members/table/role_dropdown.vue';
import MemberActionButtons from '~/vue_shared/components/members/table/member_action_buttons.vue';
import * as initUserPopovers from '~/user_popovers';
import { member as memberMock, invite, accessRequest } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MemberList', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      state: {
        members: [],
        tableFields: [],
        sourceId: 1,
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
      ],
    });
  };

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  const getByTestId = (id, options) =>
    createWrapper(getByTestIdHelper(wrapper.element, id, options));

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('fields', () => {
    const memberCanUpdate = {
      ...memberMock,
      canUpdate: true,
      source: { ...memberMock.source, id: 1 },
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
      ${'expiration'} | ${'Expiration'}     | ${memberMock}      | ${null}
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

    it('renders "Actions" field for screen readers', () => {
      createComponent({ members: [memberMock], tableFields: ['actions'] });

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
});
