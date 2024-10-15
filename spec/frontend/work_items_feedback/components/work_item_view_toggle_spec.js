import { GlToggle, GlBadge, GlPopover, GlLink } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import userPreferencesQuery from '~/work_items_feedback/graphql/user_preferences.query.graphql';
import setUseWorkItemsView from '~/work_items_feedback/graphql/set_use_work_items_view.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockUserPreferences } from 'jest/work_items/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

import WorkItemToggle from '~/work_items_feedback/components/work_item_view_toggle.vue';

describe('WorkItemToggle', () => {
  Vue.use(VueApollo);
  useMockLocationHelper();
  let wrapper;

  const userPreferencesViewOnQueryHandler = jest.fn().mockResolvedValue(mockUserPreferences());
  const userPreferencesViewsOffQueryHandler = jest
    .fn()
    .mockResolvedValue(mockUserPreferences(false));

  const mutationHandler = jest.fn().mockResolvedValue({
    data: {
      userPreferencesUpdate: {
        userPreferences: {
          useWorkItemsView: true,
        },
      },
    },
  });

  const createComponent = ({
    userPreferencesQueryHandler = userPreferencesViewOnQueryHandler,
    mutationHandler: providedMutationHandler = mutationHandler,
  } = {}) => {
    const apolloProvider = createMockApollo([
      [userPreferencesQuery, userPreferencesQueryHandler],
      [setUseWorkItemsView, providedMutationHandler],
    ]);
    wrapper = shallowMountExtended(WorkItemToggle, {
      apolloProvider,
      stubs: {
        GlBadge,
        GlPopover,
        GlLink,
        GlToggle,
      },
    });
  };

  const findToggle = () => wrapper.findComponent(GlToggle);

  describe('template', () => {
    it('displays the toggle on if useWorkItemsView from GraphQL API is on', async () => {
      createComponent();
      await waitForPromises();
      expect(findToggle().props('value')).toBe(true);
    });

    it('displays the toggle off if useWorkItemsView from GraphQL API is off', async () => {
      createComponent({ userPreferencesQueryHandler: userPreferencesViewsOffQueryHandler });
      await waitForPromises();
      expect(findToggle().props('value')).toBe(false);
    });
  });

  describe('interaction', () => {
    it('sends a mutation if toggled', async () => {
      createComponent();
      await waitForPromises();

      await findToggle().vm.$emit('change', false);

      expect(mutationHandler).toHaveBeenCalledWith({
        useWorkItemsView: false,
      });
    });

    it('refreshes the view if mutation is successful', async () => {
      createComponent();
      await waitForPromises();

      await findToggle().vm.$emit('change', true);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(window.location.reload).toHaveBeenCalled();
    });

    it('does not refresh the view if mutation fails', async () => {
      const errorMutationHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
      createComponent({ mutationHandler: errorMutationHandler });
      await waitForPromises();

      await findToggle().vm.$emit('change', false);

      await waitForPromises();

      expect(findToggle().props('value')).toBe(true);
      expect(window.location.reload).not.toHaveBeenCalled();
    });
  });
});
