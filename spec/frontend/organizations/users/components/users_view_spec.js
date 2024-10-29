import { GlLoadingIcon, GlKeysetPagination, GlCollapsibleListbox } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UsersView from '~/organizations/users/components/users_view.vue';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import { pageInfoMultiplePages } from 'jest/organizations/mock_data';
import { MOCK_PATHS, MOCK_USERS_FORMATTED } from '../mock_data';

describe('UsersView', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mountExtended(UsersView, {
      propsData: {
        loading: false,
        users: MOCK_USERS_FORMATTED,
        pageInfo: pageInfoMultiplePages,
        ...props,
      },
      provide: {
        paths: MOCK_PATHS,
      },
    });
  };

  const findGlLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findUsersTable = () => wrapper.findComponent(UsersTable);
  const findGlKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);

  describe.each`
    description                            | loading  | usersData
    ${'when loading'}                      | ${true}  | ${[]}
    ${'when not loading and has users'}    | ${false} | ${MOCK_USERS_FORMATTED}
    ${'when not loading and has no users'} | ${false} | ${[]}
  `('$description', ({ loading, usersData }) => {
    beforeEach(() => {
      createComponent({ loading, users: usersData });
    });

    it(`does ${loading ? '' : 'not '}render loading icon`, () => {
      expect(findGlLoading().exists()).toBe(loading);
    });

    it(`does ${!loading ? '' : 'not '}render users table`, () => {
      expect(findUsersTable().exists()).toBe(!loading);
    });

    it(`does ${!loading ? '' : 'not '}render pagination`, () => {
      expect(findGlKeysetPagination().exists()).toBe(Boolean(!loading));
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      createComponent();
    });

    it('@next event forwards up to the parent component', () => {
      findGlKeysetPagination().vm.$emit('next');

      expect(wrapper.emitted('next')).toHaveLength(1);
    });

    it('@prev event forwards up to the parent component', () => {
      findGlKeysetPagination().vm.$emit('prev');

      expect(wrapper.emitted('prev')).toHaveLength(1);
    });
  });

  describe('Organization role', () => {
    describe('when user has permissions to change organization role', () => {
      const users = MOCK_USERS_FORMATTED.map((user) => ({
        ...user,
        userPermissions: { ...user.userPermissions, adminOrganization: true },
      }));

      beforeEach(() => {
        createComponent({
          loading: false,
          users,
        });
      });

      it('renders listbox with role options', () => {
        expect(wrapper.findComponent(GlCollapsibleListbox).props()).toMatchObject({
          items: [
            {
              text: 'User',
              value: 'DEFAULT',
            },
            {
              text: 'Owner',
              value: 'OWNER',
            },
          ],
          selected: users[0].accessLevel.stringValue,
        });
      });
    });

    describe('when does not have permissions to change organization role', () => {
      beforeEach(() => {
        createComponent({ loading: false, users: MOCK_USERS_FORMATTED });
      });

      it('renders role as text', () => {
        expect(wrapper.findByRole('cell', { name: 'User' }).exists()).toBe(true);
      });
    });
  });
});
