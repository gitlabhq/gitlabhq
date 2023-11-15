import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UsersView from '~/organizations/users/components/users_view.vue';
import UsersTable from '~/vue_shared/components/users_table/users_table.vue';
import { MOCK_PATHS, MOCK_USERS_FORMATTED } from '../mock_data';

describe('UsersView', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(UsersView, {
      propsData: {
        loading: false,
        users: MOCK_USERS_FORMATTED,
        ...props,
      },
      provide: {
        paths: MOCK_PATHS,
      },
    });
  };

  const findGlLoading = () => wrapper.findComponent(GlLoadingIcon);
  const findUsersTable = () => wrapper.findComponent(UsersTable);

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
  });
});
