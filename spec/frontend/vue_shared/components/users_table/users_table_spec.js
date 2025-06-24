import { GlTable, GlSkeletonLoader } from '@gitlab/ui';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import UserAvatar from '~/vue_shared/components/users_table/user_avatar.vue';
import UserDate from '~/vue_shared/components/user_date.vue';
import { FIELD_NAME, FIELD_ORGANIZATION_ROLE } from '~/vue_shared/components/users_table/constants';
import { MOCK_USERS, MOCK_ADMIN_USER_PATH, MOCK_MEMBERSHIP_COUNTS } from './mock_data';

describe('UsersTable component', () => {
  let wrapper;
  const user = MOCK_USERS[0];

  const findUserGroupCount = (id) => wrapper.findByTestId(`user-group-count-${id}`);
  const findUserGroupCountLoader = (id) => findUserGroupCount(id).findComponent(GlSkeletonLoader);

  const findUserProjectCount = (id) => wrapper.findByTestId(`user-project-count-${id}`);
  const findUserProjectCountLoader = (id) => findUserGroupCount(id).findComponent(GlSkeletonLoader);

  const getCellByLabel = (trIdx, label) => {
    return wrapper
      .findComponent(GlTable)
      .find('tbody')
      .findAll('tr')
      .at(trIdx)
      .find(`[data-label="${label}"]`);
  };

  const initComponent = (props = {}, scopedSlots = {}) => {
    wrapper = mountExtended(UsersTable, {
      propsData: {
        users: MOCK_USERS,
        adminUserPath: MOCK_ADMIN_USER_PATH,
        membershipCounts: MOCK_MEMBERSHIP_COUNTS,
        membershipCountsLoading: false,
        ...props,
      },
      scopedSlots,
    });
  };

  describe('when there are users', () => {
    beforeEach(() => {
      initComponent();
    });

    it.each`
      component     | label
      ${UserAvatar} | ${'Name'}
      ${UserDate}   | ${'Created on'}
      ${UserDate}   | ${'Last activity'}
    `('renders the component for column $label', ({ component, label }) => {
      expect(getCellByLabel(0, label).findComponent(component).exists()).toBe(true);
    });
  });

  describe('when users is an empty array', () => {
    beforeEach(() => {
      initComponent({ users: [] });
    });

    it('renders EmptyResult component', () => {
      expect(wrapper.findComponent(EmptyResult).exists()).toBe(true);
    });
  });

  describe('group and project counts', () => {
    describe('when membershipCountsLoading is true', () => {
      beforeEach(() => {
        initComponent({ membershipCountsLoading: true });
      });

      it('renders a loader for each user', () => {
        expect(findUserGroupCountLoader(user.id).exists()).toBe(true);
        expect(findUserProjectCountLoader(user.id).exists()).toBe(true);
      });
    });

    describe('when membershipCounts has data', () => {
      beforeEach(() => {
        initComponent();
      });

      it("renders the user's group and project count", () => {
        expect(findUserGroupCount(user.id).text()).toBe('5');
        expect(findUserProjectCount(user.id).text()).toBe('10');
      });
    });

    describe('when membershipCounts has no data', () => {
      beforeEach(() => {
        initComponent({ membershipCounts: {} });
      });

      it("renders the user's group and project count as 0", () => {
        expect(findUserGroupCount(user.id).text()).toBe('0');
        expect(findUserProjectCount(user.id).text()).toBe('0');
      });
    });
  });

  describe('when fieldsToRender prop is passed', () => {
    beforeEach(() => {
      initComponent({ fieldsToRender: [FIELD_NAME] });
    });

    it('only renders specified fields', () => {
      expect(getCellByLabel(0, 'Name').exists()).toBe(true);
      expect(getCellByLabel(0, 'Created on').exists()).toBe(false);
    });
  });

  describe('when columnWidths prop is passed', () => {
    beforeEach(() => {
      initComponent({ columnWidths: { [FIELD_NAME]: 'gl-w-5/20' } });
    });

    it('sets th CSS class', () => {
      expect(wrapper.findByRole('columnheader', { name: 'Name' }).classes()).toContain('gl-w-5/20');
    });
  });

  it('renders organization role slot', () => {
    initComponent(
      { fieldsToRender: [FIELD_ORGANIZATION_ROLE] },
      { 'organization-role': '<div data-testid="organization-role-slot"></div>' },
    );

    expect(wrapper.findByTestId('organization-role-slot').exists()).toBe(true);
  });
});
