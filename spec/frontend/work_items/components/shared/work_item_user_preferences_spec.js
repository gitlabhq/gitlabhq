import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlToggle, GlDisclosureDropdownItem } from '@gitlab/ui';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemsListPreferences from '~/work_items/components/shared/work_item_user_preferences.vue';
import updateWorkItemsDisplaySettings from '~/work_items/graphql/update_user_preferences.mutation.graphql';
import workItemDisplaySettingsQuery from '~/work_items/graphql/get_user_preferences.query.graphql';

Vue.use(VueApollo);

jest.mock('~/alert');

const updatedUserPreferences = {
  __typename: 'UserPreferences',
  workItemsDisplaySettings: { shouldOpenItemsInSidePanel: false },
};

const originalUserPreferences = {
  currentUser: {
    __typename: 'User',
    id: 'gid://gitlab/User/1',
    userPreferences: {
      __typename: 'UserPreferences',
      workItemsDisplaySettings: { shouldOpenItemsInSidePanel: true },
    },
  },
};

describe('WorkItemsListPreferences', () => {
  let wrapper;
  let mockApolloProvider;

  const successHandler = jest.fn().mockResolvedValue({
    data: {
      userPreferencesUpdate: {
        __typename: 'UserPreferencesUpdatePayload',
        userPreferences: updatedUserPreferences,
        errors: [],
      },
    },
  });

  const createComponent = ({ props = {}, provide = {}, mutationHandler = successHandler } = {}) => {
    mockApolloProvider = createMockApollo([[updateWorkItemsDisplaySettings, mutationHandler]]);
    mockApolloProvider.clients.defaultClient.cache.writeQuery({
      query: workItemDisplaySettingsQuery,
      data: originalUserPreferences,
    });

    wrapper = shallowMount(WorkItemsListPreferences, {
      apolloProvider: mockApolloProvider,
      propsData: {
        displaySettings: { shouldOpenItemsInSidePanel: true },
        ...props,
      },
      provide: { isSignedIn: true, ...provide },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  describe('when user is signed in', () => {
    it('renders dropdown with toggle', () => {
      createComponent();
      expect(findDropdown().exists()).toBe(true);
      expect(findToggle().exists()).toBe(true);
    });

    it('renders toggle with correct initial value', () => {
      createComponent();
      expect(findToggle().props('value')).toBe(true);
    });

    it('handles empty displaySettings gracefully', () => {
      createComponent({ props: { displaySettings: {} } });
      expect(findToggle().props('value')).toBe(true); // defaults to true
    });

    describe('when toggle is clicked', () => {
      it('saves preference and updates Apollo Client cache on success', async () => {
        createComponent();

        findDropdownItem().vm.$emit('action');
        await waitForPromises();

        expect(successHandler).toHaveBeenCalledWith({
          input: {
            workItemsDisplaySettings: { shouldOpenItemsInSidePanel: false },
          },
        });
        const updatedCacheData = mockApolloProvider.clients.defaultClient.cache.readQuery({
          query: workItemDisplaySettingsQuery,
        });
        expect(updatedCacheData).toEqual({
          currentUser: {
            ...originalUserPreferences.currentUser,
            userPreferences: updatedUserPreferences,
          },
        });
      });

      it('shows loading state while saving', async () => {
        createComponent();

        // Store the initial state
        expect(findToggle().props('isLoading')).toBe(false);

        findDropdownItem().vm.$emit('action');
        await nextTick();

        // Check loading state
        expect(findToggle().props('isLoading')).toBe(true);

        await waitForPromises();

        // Check state after loading
        expect(findToggle().props('isLoading')).toBe(false);
      });

      it('handles mutation errors gracefully', async () => {
        const error = new Error('Network error');
        const errorHandler = jest.fn().mockRejectedValue(error);

        createComponent({ mutationHandler: errorHandler });

        findDropdownItem().vm.$emit('action');
        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while saving the preference.',
          captureError: true,
          error,
        });
        expect(wrapper.emitted('displaySettingsChanged')).toBeUndefined();
      });
    });

    describe('dropdown visibility', () => {
      beforeEach(() => {
        createComponent();
      });

      it('shows tooltip when dropdown is closed', () => {
        expect(wrapper.vm.tooltipText).toBe('Display options');
      });

      it('hides tooltip when dropdown is open', async () => {
        findDropdown().vm.$emit('shown');
        await nextTick();
        expect(wrapper.vm.tooltipText).toBe('');
      });
    });
  });

  describe('when user is not signed in', () => {
    it('does not render dropdown', () => {
      createComponent({ provide: { isSignedIn: false } });
      expect(findDropdown().exists()).toBe(false);
    });
  });
});
