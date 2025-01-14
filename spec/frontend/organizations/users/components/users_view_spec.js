import { GlLoadingIcon, GlKeysetPagination, GlButton } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import UserDetailsDrawer from '~/organizations/users/components/user_details_drawer.vue';
import UsersView from '~/organizations/users/components/users_view.vue';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import { pageInfoMultiplePages } from 'jest/organizations/mock_data';
import { ACCESS_LEVEL_LABEL } from '~/organizations/shared/constants';
import { MOCK_PATHS, MOCK_USERS_FORMATTED } from '../mock_data';

describe('UsersView', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMount, props = {} } = {}) => {
    wrapper = mountFn(UsersView, {
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
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findUserDetailsDrawer = () => wrapper.findComponent(UserDetailsDrawer);
  const findUsersTable = () => wrapper.findComponent(UsersTable);

  describe.each`
    description                            | loading  | usersData
    ${'when loading'}                      | ${true}  | ${[]}
    ${'when not loading and has users'}    | ${false} | ${MOCK_USERS_FORMATTED}
    ${'when not loading and has no users'} | ${false} | ${[]}
  `('$description', ({ loading, usersData }) => {
    beforeEach(() => {
      createComponent({ props: { loading, users: usersData } });
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
    const mockUser = MOCK_USERS_FORMATTED[0];

    beforeEach(() => {
      createComponent({ mountFn: mount });
    });

    it("render an organization role button with the user's role", () => {
      const userAccessLevel = mockUser.accessLevel.stringValue;

      expect(findGlButton().text()).toBe(ACCESS_LEVEL_LABEL[userAccessLevel]);
    });

    describe('when the organization role button is clicked', () => {
      beforeEach(async () => {
        await findGlButton().trigger('click');
      });

      it("sets the user details drawer's active user to selected user", () => {
        expect(findUserDetailsDrawer().props('user')).toBe(mockUser);
      });

      describe('when the user details drawer is closed', () => {
        it("reset the user details drawer's active user to null", async () => {
          await findUserDetailsDrawer().vm.$emit('close');

          expect(findGlButton().props('user')).toBeUndefined();
        });
      });
    });

    describe('when the user details drawer is loading', () => {
      it('disable the organization role button', async () => {
        await findUserDetailsDrawer().vm.$emit('loading', true);

        expect(findGlButton().props('disabled')).toBe(true);
      });
    });

    describe('when the user role has been changed', () => {
      it('emits role-change event', async () => {
        await findUserDetailsDrawer().vm.$emit('role-change');

        expect(wrapper.emitted('role-change')).toHaveLength(1);
      });
    });
  });
});
