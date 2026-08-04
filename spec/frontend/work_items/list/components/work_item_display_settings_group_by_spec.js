import { GlLoadingIcon, GlSearchBoxByType, GlToggle } from '@gitlab/ui';
import gql from 'graphql-tag';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { resolvers } from '~/graphql_shared/issuable_client';
import workItemsGroupByVisibleGroupsQuery from '~/work_items/board/grouping/graphql/client/visible_groups.query.graphql';
import WorkItemDisplaySettingsGroupBy from '~/work_items/list/components/work_item_display_settings_group_by.vue';
import { groupingStrategyFor } from '~/work_items/board/grouping';
import {
  persistMetadataPreference,
  alertPreferenceError,
} from '~/work_items/list/display_settings_preferences';
import { buildStatus } from '../../board/mock_data';

jest.mock('~/alert');
jest.mock('~/work_items/list/display_settings_preferences', () => ({
  persistMetadataPreference: jest.fn(),
  alertPreferenceError: jest.fn(),
}));
// The drawer's behaviour is the same on CE and EE, so a mock strategy stands in
// for whichever real one `ee_else_ce` resolves to (a no-op placeholder in CE).
jest.mock('~/work_items/board/grouping', () => ({
  ...jest.requireActual('~/work_items/board/grouping'),
  groupingStrategyFor: jest.fn(),
}));

Vue.use(VueApollo);

// Needed for a mocked strategy, rather than creating a whole .graphql file.
const mockGroupByValuesQuery = gql`
  query mockGroupByValues($fullPath: ID!) {
    statuses {
      id
      name
      iconName
      color
      category
    }
  }
`;

describe('WorkItemDisplaySettingsGroupBy', () => {
  let wrapper;
  let groupByValuesHandler;

  const statuses = [buildStatus(1, 'Triage'), buildStatus(2, 'To do')];
  // getGroupId scopes the id to the status grouping: `status:<gid>`.
  const groupId = (status) => `status:${status.id}`;

  const findGroupByListbox = () => wrapper.findComponentByTestId('group-by-listbox');
  const findSortListbox = () => wrapper.findComponentByTestId('sort-listbox');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findHideAll = () => wrapper.findByTestId('hide-all');
  const findToggles = () => wrapper.findAllComponents(GlToggle);
  const findNoGroupsFound = () => wrapper.findByTestId('no-groups-found');

  beforeEach(() => {
    groupByValuesHandler = jest.fn().mockResolvedValue({ data: { statuses } });
    groupingStrategyFor.mockReturnValue({
      property: 'status',
      label: 'Status',
      valuesQuery: mockGroupByValuesQuery,
      headerDecoration: () => ({ type: 'none' }),
      extractValues: (data) => data?.statuses ?? [],
    });
  });

  const createComponent = ({ props = {}, visibleGroups = null } = {}) => {
    const apolloProvider = createMockApollo(
      [[mockGroupByValuesQuery, groupByValuesHandler]],
      resolvers,
    );
    apolloProvider.clients.defaultClient.writeQuery({
      query: workItemsGroupByVisibleGroupsQuery,
      data: { workItemsGroupByVisibleGroups: visibleGroups },
    });

    wrapper = shallowMountExtended(WorkItemDisplaySettingsGroupBy, {
      apolloProvider,
      propsData: {
        fullPath: 'group/full/path',
        workItemTypeId: 'gid://gitlab/WorkItems::Type/1',
        sortKey: 'CREATED_DESC',
        ...props,
      },
    });
  };

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a disabled Group by dropdown showing the current strategy label', () => {
      expect(findGroupByListbox().props()).toMatchObject({
        disabled: true,
        toggleText: 'Status',
        selected: 'status',
      });
    });

    it('renders a disabled Sort dropdown showing Ascending', () => {
      expect(findSortListbox().props()).toMatchObject({
        disabled: true,
        toggleText: 'Ascending',
        selected: 'asc',
      });
    });

    it('renders an enabled search box', () => {
      expect(findSearchBox().props('disabled')).toBe(false);
    });
  });

  describe('while the group values query is in flight', () => {
    beforeEach(() => {
      // Never resolves within this test, so the query stays in its loading state.
      groupByValuesHandler.mockReturnValue(new Promise(() => {}));
      createComponent();
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when the group values query resolves', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('hides the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders an enabled toggle for each status, shown by default', () => {
      const toggles = findToggles();
      expect(toggles).toHaveLength(2);
      expect(toggles.at(0).props()).toMatchObject({ value: true, label: 'Triage' });
      expect(toggles.at(1).props()).toMatchObject({ value: true, label: 'To do' });
    });
  });

  describe('when the group values query fails', () => {
    const error = new Error('nope');

    beforeEach(async () => {
      groupByValuesHandler.mockRejectedValueOnce(error);
      createComponent();
      await waitForPromises();
    });

    it('surfaces an alert', () => {
      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Something went wrong while fetching the groups.',
          captureError: true,
          error,
        }),
      );
    });
  });

  describe('when only some groups are visible', () => {
    beforeEach(async () => {
      // planning_view.vue hydrates this cache from namespacePreferences before
      // the drawer mounts.
      createComponent({ visibleGroups: [groupId(statuses[0])] });
      await waitForPromises();
    });

    it('only turns on the toggles for the visible groups', () => {
      expect(findToggles().at(0).props('value')).toBe(true);
      expect(findToggles().at(1).props('value')).toBe(false);
    });
  });

  describe('toggling group visibility', () => {
    describe('when a group is hidden', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();

        findToggles().at(1).vm.$emit('change');
        await waitForPromises();
      });

      it('persists the remaining visible groups', () => {
        expect(persistMetadataPreference).toHaveBeenCalledWith({
          apolloClient: expect.anything(),
          namespace: 'group/full/path',
          workItemTypeId: 'gid://gitlab/WorkItems::Type/1',
          userPreferencesOnly: false,
          displaySettings: { visibleGroups: [groupId(statuses[0])] },
          sort: 'CREATED_DESC',
        });
      });
    });

    describe('when the last hidden group is toggled back on', () => {
      beforeEach(async () => {
        createComponent({
          props: { namespacePreferences: { visibleGroups: [groupId(statuses[0])] } },
          visibleGroups: [groupId(statuses[0])],
        });
        await waitForPromises();

        findToggles().at(1).vm.$emit('change');
        await waitForPromises();
      });

      it('normalizes the persisted visible groups back to null', () => {
        expect(persistMetadataPreference).toHaveBeenCalledWith(
          expect.objectContaining({ displaySettings: { visibleGroups: null } }),
        );
      });
    });

    describe('when other display settings are already persisted', () => {
      beforeEach(async () => {
        createComponent({
          props: { namespacePreferences: { hiddenMetadataKeys: ['labels'] } },
        });
        await waitForPromises();

        findToggles().at(0).vm.$emit('change');
        await waitForPromises();
      });

      it('preserves them alongside the visible groups', () => {
        expect(persistMetadataPreference).toHaveBeenCalledWith(
          expect.objectContaining({
            displaySettings: {
              hiddenMetadataKeys: ['labels'],
              visibleGroups: [groupId(statuses[1])],
            },
          }),
        );
      });
    });

    describe('when the view is a saved view', () => {
      beforeEach(async () => {
        createComponent({ props: { isSavedView: true } });
        await waitForPromises();

        findToggles().at(1).vm.$emit('change');
        await waitForPromises();
      });

      it('emits update-settings with the visible groups', () => {
        expect(wrapper.emitted('update-settings')).toEqual([
          [{ visibleGroups: [groupId(statuses[0])] }],
        ]);
      });

      it('does not persist the preference', () => {
        expect(persistMetadataPreference).not.toHaveBeenCalled();
      });
    });

    describe('when persistence fails', () => {
      const error = new Error('nope');

      beforeEach(async () => {
        persistMetadataPreference.mockRejectedValueOnce(error);
        createComponent();
        await waitForPromises();

        findToggles().at(0).vm.$emit('change');
        await waitForPromises();
      });

      it('surfaces an alert', () => {
        expect(alertPreferenceError).toHaveBeenCalledWith(error);
      });
    });
  });

  describe('search', () => {
    describe('when the search matches only some groups', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();

        findSearchBox().vm.$emit('input', 'tri');
        await waitForPromises();
      });

      it('filters the toggle list by name, case-insensitively', () => {
        const toggles = findToggles();
        expect(toggles).toHaveLength(1);
        expect(toggles.at(0).props('label')).toBe('Triage');
      });

      describe('when the search is cleared', () => {
        beforeEach(async () => {
          findSearchBox().vm.$emit('input', '');
          await waitForPromises();
        });

        it('restores the full list', () => {
          expect(findToggles()).toHaveLength(2);
        });
      });

      describe('when the matching group is toggled off', () => {
        beforeEach(async () => {
          findToggles().at(0).vm.$emit('change');
          await waitForPromises();
        });

        it('computes the persisted visible groups against the full status set, not the filtered view', () => {
          // Only "Triage" is rendered while filtered, but toggling it off must
          // still leave "To do" (filtered out of view) recorded as visible.
          expect(persistMetadataPreference).toHaveBeenCalledWith(
            expect.objectContaining({ displaySettings: { visibleGroups: [groupId(statuses[1])] } }),
          );
        });
      });

      describe('when Hide all is clicked', () => {
        beforeEach(async () => {
          findHideAll().trigger('click');
          await waitForPromises();
        });

        it('still hides every group, not just the filtered ones', () => {
          expect(persistMetadataPreference).toHaveBeenCalledWith(
            expect.objectContaining({ displaySettings: { visibleGroups: [] } }),
          );
        });
      });
    });

    describe('when the search matches nothing', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();

        findSearchBox().vm.$emit('input', 'no such status');
        await waitForPromises();
      });

      it('renders no toggles', () => {
        expect(findToggles()).toHaveLength(0);
      });

      it('shows the empty state', () => {
        expect(findNoGroupsFound().text()).toBe('No groups match your search.');
      });
    });
  });

  describe('Hide all', () => {
    it('persists an empty visibleGroups array', async () => {
      createComponent();
      await waitForPromises();

      findHideAll().trigger('click');
      await waitForPromises();

      expect(persistMetadataPreference).toHaveBeenCalledWith(
        expect.objectContaining({ displaySettings: { visibleGroups: [] } }),
      );
    });

    describe('when every group is already hidden', () => {
      beforeEach(async () => {
        createComponent({ visibleGroups: [] });
        await waitForPromises();

        findHideAll().trigger('click');
        await waitForPromises();
      });

      it('does not persist again', () => {
        expect(persistMetadataPreference).not.toHaveBeenCalled();
      });
    });
  });
});
