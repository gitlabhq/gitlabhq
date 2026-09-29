import { GlLoadingIcon, GlSearchBoxByType, GlToggle } from '@gitlab/ui';
import gql from 'graphql-tag';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { createAlert } from '~/alert';
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
  let apolloProvider;

  const statuses = [buildStatus(1, 'Triage'), buildStatus(2, 'To do')];
  // getGroupId scopes the id to the status grouping: `status:<gid>`.
  const groupId = (status) => `status:${status.id}`;

  const findGroupByListbox = () => wrapper.findComponentByTestId('group-by-listbox');
  const findSortListbox = () => wrapper.findComponentByTestId('sort-listbox');
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findHideAll = () => wrapper.findByTestId('hide-all');
  const findToggles = () => wrapper.findAllComponents(GlToggle);
  const findShownSection = () => wrapper.findByTestId('shown-groups');
  const findHiddenSection = () => wrapper.findByTestId('hidden-groups');
  const findShownToggles = () => findShownSection().findAllComponents(GlToggle);
  const findHiddenToggles = () => findHiddenSection().findAllComponents(GlToggle);
  const findNoGroupsFound = () => wrapper.findByTestId('no-groups-found');
  const findGroupLimitHint = () => wrapper.findByTestId('group-limit-hint');

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
    apolloProvider = createMockApollo([[mockGroupByValuesQuery, groupByValuesHandler]]);

    wrapper = shallowMountExtended(WorkItemDisplaySettingsGroupBy, {
      apolloProvider,
      propsData: {
        fullPath: 'group/full/path',
        workItemTypeId: 'gid://gitlab/WorkItems::Type/1',
        sortKey: 'CREATED_DESC',
        namespacePreferences: { visibleGroups },
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

    it('renders an enabled Sort dropdown with Ascending selected by default', () => {
      expect(findSortListbox().props()).toMatchObject({
        disabled: false,
        toggleText: 'Ascending',
        selected: 'asc',
        items: [
          { text: 'Ascending', value: 'asc' },
          { text: 'Descending', value: 'desc' },
        ],
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

    it('renders a toggle for each status', () => {
      expect(findToggles()).toHaveLength(2);
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

  describe('shown and hidden sections', () => {
    it('lists every group under Shown when they are all visible', async () => {
      createComponent();
      await waitForPromises();

      expect(findShownToggles().wrappers.map((toggle) => toggle.props('label'))).toEqual([
        'Triage',
        'To do',
      ]);
      expect(findHiddenSection().exists()).toBe(false);
    });

    it('splits the groups across both sections when only some are visible', async () => {
      createComponent({ visibleGroups: [groupId(statuses[0])] });
      await waitForPromises();

      expect(findShownToggles().wrappers.map((toggle) => toggle.props('label'))).toEqual([
        'Triage',
      ]);
      expect(findHiddenToggles().wrappers.map((toggle) => toggle.props('label'))).toEqual([
        'To do',
      ]);
    });

    it('lists every group under Hidden when none are visible', async () => {
      createComponent({ visibleGroups: [] });
      await waitForPromises();

      expect(findShownSection().exists()).toBe(false);
      expect(findHiddenToggles().wrappers.map((toggle) => toggle.props('label'))).toEqual([
        'Triage',
        'To do',
      ]);
    });
  });

  describe('when the persisted selection changes', () => {
    it('moves the newly hidden group into the Hidden section', async () => {
      createComponent();
      await waitForPromises();

      await wrapper.setProps({ namespacePreferences: { visibleGroups: [groupId(statuses[0])] } });

      expect(findShownToggles().at(0).props('label')).toBe('Triage');
      expect(findHiddenToggles().at(0).props('label')).toBe('To do');
    });
  });

  describe('sorting groups', () => {
    it('selects Descending when it is the persisted groupSort', async () => {
      createComponent({ props: { namespacePreferences: { groupSort: 'desc' } } });
      await waitForPromises();

      expect(findSortListbox().props()).toMatchObject({
        toggleText: 'Descending',
        selected: 'desc',
      });
    });

    it('reverses the group order when groupSort is desc', async () => {
      createComponent({ props: { namespacePreferences: { groupSort: 'desc' } } });
      await waitForPromises();

      expect(findShownToggles().wrappers.map((toggle) => toggle.props('label'))).toEqual([
        'To do',
        'Triage',
      ]);
    });

    it('includes Manual as an option only while it is the current sort (a pre-existing drag)', async () => {
      createComponent({ props: { namespacePreferences: { groupOrder: [groupId(statuses[1])] } } });
      await waitForPromises();

      expect(findSortListbox().props()).toMatchObject({ toggleText: 'Manual', selected: 'manual' });
      expect(findSortListbox().props('items')).toContainEqual({ text: 'Manual', value: 'manual' });
    });

    it('omits Manual when Ascending or Descending is the current sort', async () => {
      createComponent();
      await waitForPromises();

      expect(findSortListbox().props('items')).not.toContainEqual(
        expect.objectContaining({ value: 'manual' }),
      );
    });

    it('does nothing when the already-active sort is re-selected', async () => {
      const groupOrder = [groupId(statuses[1])];
      createComponent({ props: { namespacePreferences: { groupOrder } } });
      await waitForPromises();

      findSortListbox().vm.$emit('select', 'manual');
      await waitForPromises();

      expect(persistMetadataPreference).not.toHaveBeenCalled();
    });

    describe('selecting a sort direction', () => {
      beforeEach(async () => {
        createComponent({ props: { namespacePreferences: { hiddenMetadataKeys: ['labels'] } } });
        await waitForPromises();

        findSortListbox().vm.$emit('select', 'desc');
        await waitForPromises();
      });

      it('persists the sort direction, merged with existing display settings, and resets groupOrder', () => {
        expect(persistMetadataPreference).toHaveBeenCalledWith(
          expect.objectContaining({
            namespace: 'group/full/path',
            displaySettings: { hiddenMetadataKeys: ['labels'], groupSort: 'desc', groupOrder: [] },
          }),
        );
      });
    });

    describe('tracking', () => {
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      it('tracks the sort direction chosen', async () => {
        createComponent();
        await waitForPromises();
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findSortListbox().vm.$emit('select', 'desc');
        await waitForPromises();

        expect(trackEventSpy).toHaveBeenCalledWith(
          'configure_columns_on_work_item_board',
          { label: 'sort_groups_desc' },
          undefined,
        );
      });

      it('does not track when the already-active sort is re-selected', async () => {
        createComponent();
        await waitForPromises();
        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        findSortListbox().vm.$emit('select', 'asc');
        await waitForPromises();

        expect(trackEventSpy).not.toHaveBeenCalled();
      });
    });

    describe('on a saved view', () => {
      it('emits update-settings with the sort direction, resetting groupOrder', async () => {
        createComponent({
          props: {
            isSavedView: true,
            namespacePreferences: { hiddenMetadataKeys: ['labels'] },
          },
        });
        await waitForPromises();

        findSortListbox().vm.$emit('select', 'desc');
        await waitForPromises();

        expect(wrapper.emitted('update-settings')).toEqual([
          [{ hiddenMetadataKeys: ['labels'], groupSort: 'desc', groupOrder: [] }],
        ]);
        expect(persistMetadataPreference).not.toHaveBeenCalled();
      });
    });
  });

  describe('toggling group visibility', () => {
    describe('when a group is hidden', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();

        findShownToggles().at(1).vm.$emit('change');
        await waitForPromises();
      });

      it('persists the visible groups as a user preference', () => {
        expect(persistMetadataPreference).toHaveBeenCalledWith(
          expect.objectContaining({
            namespace: 'group/full/path',
            sort: 'CREATED_DESC',
            displaySettings: { visibleGroups: [groupId(statuses[0])] },
          }),
        );
      });
    });

    describe('when persistence fails', () => {
      const error = new Error('nope');

      beforeEach(async () => {
        persistMetadataPreference.mockRejectedValueOnce(error);
        createComponent();
        await waitForPromises();

        findShownToggles().at(0).vm.$emit('change');
        await waitForPromises();
      });

      it('surfaces an alert', () => {
        expect(alertPreferenceError).toHaveBeenCalledWith(error);
      });
    });

    describe('when the last hidden group is toggled back on', () => {
      beforeEach(async () => {
        createComponent({
          props: { namespacePreferences: { visibleGroups: [groupId(statuses[0])] } },
        });
        await waitForPromises();

        findHiddenToggles().at(0).vm.$emit('change');
        await waitForPromises();
      });

      it('normalizes the persisted selection back to null', () => {
        expect(persistMetadataPreference).toHaveBeenCalledWith(
          expect.objectContaining({ displaySettings: { visibleGroups: null } }),
        );
      });
    });

    describe('when the view is a saved view', () => {
      beforeEach(async () => {
        createComponent({ props: { isSavedView: true } });
        await waitForPromises();

        findShownToggles().at(1).vm.$emit('change');
        await waitForPromises();
      });

      it('emits update-settings with the visible groups', () => {
        expect(wrapper.emitted('update-settings')).toEqual([
          [{ visibleGroups: [groupId(statuses[0])] }],
        ]);
      });

      it('does not persist visible groups as a user preference', () => {
        expect(persistMetadataPreference).not.toHaveBeenCalled();
      });

      describe('when other display settings are already saved', () => {
        beforeEach(async () => {
          createComponent({
            props: { isSavedView: true, namespacePreferences: { hiddenMetadataKeys: ['labels'] } },
          });
          await waitForPromises();

          findShownToggles().at(0).vm.$emit('change');
          await waitForPromises();
        });

        it('preserves them alongside the visible groups in the emitted settings', () => {
          expect(wrapper.emitted('update-settings')).toEqual([
            [{ hiddenMetadataKeys: ['labels'], visibleGroups: [groupId(statuses[1])] }],
          ]);
        });
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
          findShownToggles().at(0).vm.$emit('change');
          await waitForPromises();
        });

        it('computes the persisted selection against the full status set, not the filtered view', () => {
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
    it('persists the visible groups as a user preference', async () => {
      createComponent();
      await waitForPromises();

      findHideAll().trigger('click');
      await waitForPromises();

      expect(persistMetadataPreference).toHaveBeenCalledWith(
        expect.objectContaining({
          namespace: 'group/full/path',
          displaySettings: { visibleGroups: [] },
        }),
      );
    });
  });

  describe('group limit', () => {
    // CE doesn't group by anything real yet (placeholder_strategy.js), so this reuses the
    // status fixture just for its id/name shape — the limit logic doesn't care what a group is.
    const buildGroupByValues = (count) =>
      Array.from({ length: count }, (_, index) => buildStatus(index, `Group ${index}`));

    describe('when there are more groups than a board can show', () => {
      const manyValues = buildGroupByValues(26);

      beforeEach(async () => {
        groupByValuesHandler.mockResolvedValue({ data: { statuses: manyValues } });
        createComponent();
        await waitForPromises();
      });

      it('hides every group, so the user has to choose', () => {
        expect(findShownSection().exists()).toBe(false);
        expect(findHiddenToggles()).toHaveLength(manyValues.length);
      });

      it('says how many groups can be selected', () => {
        expect(findGroupLimitHint().text()).toBe('Select up to 25 groups.');
      });

      it('persists only the group toggled on', async () => {
        findHiddenToggles().at(3).vm.$emit('change');
        await waitForPromises();

        expect(persistMetadataPreference).toHaveBeenCalledWith(
          expect.objectContaining({
            namespace: 'group/full/path',
            displaySettings: { visibleGroups: [groupId(manyValues[3])] },
          }),
        );
      });
    });

    describe('when the limit is reached', () => {
      const manyValues = buildGroupByValues(30);
      const shown = manyValues.slice(0, 25);

      beforeEach(async () => {
        groupByValuesHandler.mockResolvedValue({ data: { statuses: manyValues } });
        createComponent({ visibleGroups: shown.map(groupId) });
        await waitForPromises();
      });

      it('disables the toggles for the hidden groups', () => {
        expect(findHiddenToggles().at(0).props('disabled')).toBe(true);
      });

      it('leaves the shown groups toggleable, so the user can swap one out', () => {
        expect(findShownToggles().at(0).props('disabled')).toBe(false);
      });
    });

    describe('when there are few enough groups to show them all', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('renders no hint', () => {
        expect(findGroupLimitHint().exists()).toBe(false);
      });

      it('leaves every toggle enabled', () => {
        expect(findToggles().wrappers.every((toggle) => toggle.props('disabled') === false)).toBe(
          true,
        );
      });
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('tracks hiding a single group', async () => {
      createComponent();
      await waitForPromises();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findShownToggles().at(1).vm.$emit('change');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'configure_columns_on_work_item_board',
        { label: 'hide_group' },
        undefined,
      );
    });

    it('tracks showing a single group', async () => {
      createComponent({ visibleGroups: [groupId(statuses[0])] });
      await waitForPromises();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findHiddenToggles().at(0).vm.$emit('change');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'configure_columns_on_work_item_board',
        { label: 'show_group' },
        undefined,
      );
    });

    it('tracks hiding all groups', async () => {
      createComponent();
      await waitForPromises();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findHideAll().trigger('click');
      await waitForPromises();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'configure_columns_on_work_item_board',
        { label: 'hide_all_groups' },
        undefined,
      );
    });
  });
});
