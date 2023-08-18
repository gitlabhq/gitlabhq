import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import UserListsComponent from '~/user_lists/components/user_lists.vue';
import UserListsTable from '~/user_lists/components/user_lists_table.vue';
import createStore from '~/user_lists/store/index';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { userList } from 'jest/feature_flags/mock_data';

jest.mock('~/api');

Vue.use(Vuex);

describe('~/user_lists/components/user_lists.vue', () => {
  const mockProvide = {
    newUserListPath: '/user-lists/new',
    featureFlagsHelpPagePath: '/help/feature-flags',
    errorStateSvgPath: '/assets/illustrations/empty-state/empty-feature-flag-md.svg',
  };

  const mockState = {
    projectId: '1',
  };

  let wrapper;
  let store;

  const factory = (provide = mockProvide, fn = mount) => {
    store = createStore(mockState);
    wrapper = fn(UserListsComponent, {
      store,
      provide,
    });
  };

  const newButton = () => within(wrapper.element).queryAllByText('New user list');

  describe('without permissions', () => {
    const provideData = {
      ...mockProvide,
      newUserListPath: null,
    };

    beforeEach(() => {
      Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [], headers: {} });
      factory(provideData);
    });

    it('does not render new user list button', () => {
      expect(newButton()).toHaveLength(0);
    });
  });

  describe('loading state', () => {
    it('renders a loading icon', () => {
      Api.fetchFeatureFlagUserLists.mockReturnValue(new Promise(() => {}));

      factory();

      const loadingElement = wrapper.findComponent(GlLoadingIcon);

      expect(loadingElement.exists()).toBe(true);
      expect(loadingElement.props('label')).toEqual('Loading user lists');
    });
  });

  describe('successful request', () => {
    describe('without user lists', () => {
      let emptyState;

      beforeEach(async () => {
        Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [], headers: {} });

        factory();
        await waitForPromises();
        await nextTick();

        emptyState = wrapper.findComponent(GlEmptyState);
      });

      it('should render the empty state', () => {
        expect(emptyState.exists()).toBe(true);
      });

      it('renders new feature flag button', () => {
        expect(newButton()).not.toHaveLength(0);
      });

      it('renders generic title', () => {
        const title = createWrapper(
          within(emptyState.element).getByText('Get started with user lists'),
        );
        expect(title.exists()).toBe(true);
      });

      it('renders generic description', () => {
        const description = createWrapper(
          within(emptyState.element).getByText(
            'User lists allow you to define a set of users to use with Feature Flags.',
          ),
        );
        expect(description.exists()).toBe(true);
      });
    });

    describe('with paginated user lists', () => {
      let table;

      beforeEach(async () => {
        Api.fetchFeatureFlagUserLists.mockResolvedValue({
          data: [userList],
          headers: {
            'x-next-page': '2',
            'x-page': '1',
            'X-Per-Page': '2',
            'X-Prev-Page': '',
            'X-TOTAL': '37',
            'X-Total-Pages': '5',
          },
        });

        factory();
        jest.spyOn(store, 'dispatch');
        await nextTick();
        table = wrapper.findComponent(UserListsTable);
      });

      it('should render a table with feature flags', () => {
        expect(table.exists()).toBe(true);
        expect(table.props('userLists')).toEqual([userList]);
      });

      it('renders new feature flag button', () => {
        expect(newButton()).not.toHaveLength(0);
      });

      describe('pagination', () => {
        let pagination;

        beforeEach(() => {
          pagination = wrapper.findComponent(TablePagination);
        });

        it('should render pagination', () => {
          expect(pagination.exists()).toBe(true);
        });

        it('should make an API request when page is clicked', () => {
          jest.spyOn(store, 'dispatch');
          pagination.vm.change('4');

          expect(store.dispatch).toHaveBeenCalledWith('setUserListsOptions', {
            page: '4',
          });
        });
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach(async () => {
      Api.fetchFeatureFlagUserLists.mockRejectedValue();
      factory();

      await nextTick();
    });

    it('should render error state', () => {
      const emptyState = wrapper.findComponent(GlEmptyState);
      const title = createWrapper(
        within(emptyState.element).getByText('There was an error fetching the user lists.'),
      );
      expect(title.exists()).toBe(true);
      const description = createWrapper(
        within(emptyState.element).getByText(
          'Try again in a few moments or contact your support team.',
        ),
      );
      expect(description.exists()).toBe(true);
    });

    it('renders new feature flag button', () => {
      expect(newButton()).not.toHaveLength(0);
    });
  });
});
