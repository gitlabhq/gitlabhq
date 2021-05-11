import { GlTable, GlSkeletonLoader } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';

import AdminUserActions from '~/admin/users/components/user_actions.vue';
import AdminUserAvatar from '~/admin/users/components/user_avatar.vue';
import AdminUsersTable from '~/admin/users/components/users_table.vue';
import getUsersGroupCountsQuery from '~/admin/users/graphql/queries/get_users_group_counts.query.graphql';
import createFlash from '~/flash';
import AdminUserDate from '~/vue_shared/components/user_date.vue';

import { users, paths, createGroupCountResponse } from '../mock_data';

jest.mock('~/flash');

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('AdminUsersTable component', () => {
  let wrapper;
  const user = users[0];

  const createFetchGroupCount = (data) =>
    jest.fn().mockResolvedValue(createGroupCountResponse(data));
  const fetchGroupCountsLoading = jest.fn().mockResolvedValue(new Promise(() => {}));
  const fetchGroupCountsError = jest.fn().mockRejectedValue(new Error('Network error'));
  const fetchGroupCountsResponse = createFetchGroupCount([{ id: user.id, groupCount: 5 }]);

  const findUserGroupCount = (id) => wrapper.findByTestId(`user-group-count-${id}`);
  const findUserGroupCountLoader = (id) => findUserGroupCount(id).find(GlSkeletonLoader);
  const getCellByLabel = (trIdx, label) => {
    return wrapper
      .find(GlTable)
      .find('tbody')
      .findAll('tr')
      .at(trIdx)
      .find(`[data-label="${label}"][role="cell"]`);
  };

  function createMockApolloProvider(resolverMock) {
    const requestHandlers = [[getUsersGroupCountsQuery, resolverMock]];

    return createMockApollo(requestHandlers);
  }

  const initComponent = (props = {}, resolverMock = fetchGroupCountsResponse) => {
    wrapper = mountExtended(AdminUsersTable, {
      localVue,
      apolloProvider: createMockApolloProvider(resolverMock),
      propsData: {
        users,
        paths,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when there are users', () => {
    beforeEach(() => {
      initComponent();
    });

    it('renders the projects count', () => {
      expect(getCellByLabel(0, 'Projects').text()).toContain(`${user.projectsCount}`);
    });

    it('renders the user actions', () => {
      expect(wrapper.find(AdminUserActions).exists()).toBe(true);
    });

    it.each`
      component          | label
      ${AdminUserAvatar} | ${'Name'}
      ${AdminUserDate}   | ${'Created on'}
      ${AdminUserDate}   | ${'Last activity'}
    `('renders the component for column $label', ({ component, label }) => {
      expect(getCellByLabel(0, label).find(component).exists()).toBe(true);
    });
  });

  describe('when users is an empty array', () => {
    beforeEach(() => {
      initComponent({ users: [] });
    });

    it('renders a "No users found" message', () => {
      expect(wrapper.text()).toContain('No users found');
    });
  });

  describe('group counts', () => {
    describe('when fetching the data', () => {
      beforeEach(() => {
        initComponent({}, fetchGroupCountsLoading);
      });

      it('renders a loader for each user', () => {
        expect(findUserGroupCountLoader(user.id).exists()).toBe(true);
      });
    });

    describe('when the data has been fetched', () => {
      beforeEach(() => {
        initComponent();
      });

      it("renders the user's group count", () => {
        expect(findUserGroupCount(user.id).text()).toBe('5');
      });

      describe("and a user's group count is null", () => {
        beforeEach(() => {
          initComponent({}, createFetchGroupCount([{ id: user.id, groupCount: null }]));
        });

        it("renders the user's group count as 0", () => {
          expect(findUserGroupCount(user.id).text()).toBe('0');
        });
      });
    });

    describe('when there is an error while fetching the data', () => {
      beforeEach(() => {
        initComponent({}, fetchGroupCountsError);
      });

      it('creates a flash message and captures the error', () => {
        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(createFlash).toHaveBeenCalledWith({
          message: 'Could not load user group counts. Please refresh the page to try again.',
          captureError: true,
          error: expect.any(Error),
        });
      });
    });
  });
});
