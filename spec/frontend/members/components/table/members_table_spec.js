import { GlBadge, GlPagination, GlTable } from '@gitlab/ui';
import {
  getByText as getByTextHelper,
  getByTestId as getByTestIdHelper,
  within,
} from '@testing-library/dom';
import { mount, createLocalVue, createWrapper } from '@vue/test-utils';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CreatedAt from '~/members/components/table/created_at.vue';
import ExpirationDatepicker from '~/members/components/table/expiration_datepicker.vue';
import ExpiresAt from '~/members/components/table/expires_at.vue';
import MemberActionButtons from '~/members/components/table/member_action_buttons.vue';
import MemberAvatar from '~/members/components/table/member_avatar.vue';
import MemberSource from '~/members/components/table/member_source.vue';
import MembersTable from '~/members/components/table/members_table.vue';
import RoleDropdown from '~/members/components/table/role_dropdown.vue';
import { MEMBER_TYPES, TAB_QUERY_PARAM_VALUES } from '~/members/constants';
import * as initUserPopovers from '~/user_popovers';
import {
  member as memberMock,
  directMember,
  invite,
  accessRequest,
  pagination,
} from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MembersTable', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBER_TYPES.invite]: {
          namespaced: true,
          state: {
            members: [],
            tableFields: [],
            tableAttrs: {
              table: { 'data-qa-selector': 'members_list' },
              tr: { 'data-qa-selector': 'member_row' },
            },
            pagination,
            ...state,
          },
        },
      },
    });
  };

  const createComponent = (state, provide = {}) => {
    wrapper = mount(MembersTable, {
      localVue,
      propsData: {
        tabQueryParamValue: TAB_QUERY_PARAM_VALUES.invite,
      },
      store: createStore(state),
      provide: {
        sourceId: 1,
        currentUserId: 1,
        namespace: MEMBER_TYPES.invite,
        ...provide,
      },
      stubs: [
        'member-avatar',
        'member-source',
        'expires-at',
        'created-at',
        'member-action-buttons',
        'role-dropdown',
        'remove-group-link-modal',
        'remove-member-modal',
        'expiration-datepicker',
      ],
    });
  };

  const url = 'https://localhost/foo-bar/-/project_members?tab=invited';

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  const getByTestId = (id, options) =>
    createWrapper(getByTestIdHelper(wrapper.element, id, options));

  const findTable = () => wrapper.find(GlTable);
  const findTableCellByMemberId = (tableCellLabel, memberId) =>
    getByTestId(`members-table-row-${memberId}`).find(
      `[data-label="${tableCellLabel}"][role="cell"]`,
    );

  const findPagination = () => extendedWrapper(wrapper.find(GlPagination));

  const expectCorrectLinkToPage2 = () => {
    expect(findPagination().findByText('2', { selector: 'a' }).attributes('href')).toBe(
      `${url}&invited_members_page=2`,
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('fields', () => {
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
          wrapper.find(`[data-label="${label}"][role="cell"]`).find(expectedComponent).exists(),
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
          wrapper.find(`[data-label="Actions"][role="cell"]`).find(MemberActionButtons).exists(),
        ).toBe(true);
      });

      describe('when user is not logged in', () => {
        it('does not render the "Actions" field', () => {
          createComponent({ tableFields: ['actions'] }, { currentUserId: null });

          expect(within(wrapper.element).queryByTestId('col-actions')).toBe(null);
        });
      });

      const memberCanRemove = {
        ...directMember,
        canRemove: true,
      };

      const memberNoPermissions = {
        ...memberMock,
        id: 2,
      };

      describe.each`
        permission     | members
        ${'canUpdate'} | ${[memberNoPermissions, memberCanUpdate]}
        ${'canRemove'} | ${[memberNoPermissions, memberCanRemove]}
        ${'canResend'} | ${[memberNoPermissions, invite]}
      `('when one of the members has $permission permissions', ({ members }) => {
        it('renders the "Actions" field', () => {
          createComponent({ members, tableFields: ['actions'] });

          expect(getByTestId('col-actions').exists()).toBe(true);

          expect(findTableCellByMemberId('Actions', members[0].id).classes()).toStrictEqual([
            'col-actions',
            'gl-display-none!',
            'gl-lg-display-table-cell!',
          ]);
          expect(findTableCellByMemberId('Actions', members[1].id).classes()).toStrictEqual([
            'col-actions',
          ]);
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

      expect(wrapper.find(`[data-label="Max role"][role="cell"]`).find(GlBadge).text()).toBe(
        memberMock.accessLevel.stringValue,
      );
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

    expect(findTable().find('tbody tr').attributes('data-qa-selector')).toBe('member_row');
  });

  describe('when required pagination data is provided', () => {
    beforeEach(() => {
      delete window.location;
    });

    it('renders `gl-pagination` component with correct props', () => {
      window.location = new URL(url);

      createComponent();

      const glPagination = findPagination();

      expect(glPagination.exists()).toBe(true);
      expect(glPagination.props()).toMatchObject({
        value: pagination.currentPage,
        perPage: pagination.perPage,
        totalItems: pagination.totalItems,
        prevText: 'Prev',
        nextText: 'Next',
        labelNextPage: 'Go to next page',
        labelPrevPage: 'Go to previous page',
        align: 'center',
      });
    });

    it('uses `pagination.paramName` to generate the pagination links', () => {
      window.location = new URL(url);

      createComponent({
        pagination: {
          currentPage: 1,
          perPage: 5,
          totalItems: 10,
          paramName: 'invited_members_page',
        },
      });

      expectCorrectLinkToPage2();
    });

    it('removes any url params defined as `null` in the `params` attribute', () => {
      window.location = new URL(`${url}&search_groups=foo`);

      createComponent({
        pagination: {
          currentPage: 1,
          perPage: 5,
          totalItems: 10,
          paramName: 'invited_members_page',
          params: { search_groups: null },
        },
      });

      expectCorrectLinkToPage2();
    });
  });

  describe.each`
    attribute        | value
    ${'paramName'}   | ${null}
    ${'currentPage'} | ${null}
    ${'perPage'}     | ${null}
    ${'totalItems'}  | ${0}
  `('when pagination.$attribute is $value', ({ attribute, value }) => {
    it('does not render `gl-pagination`', () => {
      createComponent({
        pagination: {
          ...pagination,
          [attribute]: value,
        },
      });

      expect(findPagination().exists()).toBe(false);
    });
  });
});
