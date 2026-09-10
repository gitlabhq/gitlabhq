import { GlAlert, GlCollapsibleListbox, GlFormRadio } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import SelectDestinationTab from '~/import/offline_transfer/import/select_destination_tab.vue';
import offlineTransferSourceOwnedGroupsQuery from '~/import/offline_transfer/graphql/queries/offline_transfer_source_owned_groups.query.graphql';
import {
  mockGroups,
  mockGroupsResponse,
  mockGroupsPage1Response,
  mockGroupsPage2Response,
  emptyGroupsResponse,
} from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('SelectDestinationTab', () => {
  let wrapper;
  let defaultHandler;

  beforeEach(() => {
    defaultHandler = jest.fn().mockResolvedValue(mockGroupsResponse);
  });

  const createComponent = ({
    propsData = {},
    handler = defaultHandler,
    mountFn = shallowMountExtended,
  } = {}) => {
    wrapper = mountFn(SelectDestinationTab, {
      propsData,
      apolloProvider: createMockApollo([[offlineTransferSourceOwnedGroupsQuery, handler]]),
    });
  };

  const topLevel = 'top_level';
  const existingGroup = 'existing_group';
  const [flightGroup, spaceGroup] = mockGroups;
  const existingGroupValue = { type: existingGroup, parentGroup: flightGroup };
  const findTopLevelCard = () => wrapper.findByTestId('top-level-card');
  const findExistingGroupCard = () => wrapper.findByTestId('existing-group-card');
  const findTopLevelRadio = () => findTopLevelCard().findComponent(GlFormRadio);
  const findExistingGroupRadio = () => findExistingGroupCard().findComponent(GlFormRadio);
  const findParentListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findParentGroupWrapper = () => wrapper.findByTestId('parent-group-group');
  const findFetchError = () => wrapper.findComponentByTestId('groups-fetch-error');
  const findNoOwnedGroupsAlert = () =>
    wrapper.findAllComponents(GlAlert).wrappers.find((alert) => alert.props('variant') === 'info');
  const selectedBorder = 'gl-border-[var(--gl-control-border-color-selected-default)]';

  describe('when import destination is toplevel', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('selects top-level groups as the import destination', () => {
      expect(findTopLevelRadio().attributes('value')).toBe(topLevel);
      expect(findTopLevelRadio().props('checked')).toBe(topLevel);
      expect(findTopLevelRadio().text()).toContain('Import all as top-level groups');
      expect(findTopLevelCard().classes()).toContain(selectedBorder);
    });

    it('renders parent group but hides the listbox', () => {
      expect(findExistingGroupRadio().text()).toContain('Import all under an existing group');
      expect(findParentListbox().exists()).toBe(false);
      expect(findExistingGroupCard().classes()).not.toContain(selectedBorder);
    });

    it('does not request users owned groups', () => {
      expect(defaultHandler).not.toHaveBeenCalled();
    });

    it('changes destination when the existing group card is clicked', async () => {
      await findExistingGroupCard().trigger('click');

      expect(wrapper.emitted('destination-input')).toEqual([
        [{ type: existingGroup, parentGroup: null }],
      ]);
    });
  });

  describe('when import destination is existing group', () => {
    const createExistingGroupTab = () =>
      createComponent({ propsData: { destinationSelection: existingGroupValue } });

    it('highlights only the existing group card', () => {
      createExistingGroupTab();
      expect(findExistingGroupCard().classes()).toContain(selectedBorder);
      expect(findTopLevelCard().classes()).not.toContain(selectedBorder);
    });

    it('requests user owned groups', () => {
      createExistingGroupTab();
      expect(defaultHandler).toHaveBeenCalledTimes(1);
    });

    describe('when groups are loading', () => {
      beforeEach(() => {
        createExistingGroupTab();
      });

      it('puts the dropdown list in a loading state', () => {
        expect(findParentListbox().props('loading')).toBe(true);
        expect(findNoOwnedGroupsAlert()).toBeUndefined();
      });
    });

    describe('when groups have loaded', () => {
      beforeEach(async () => {
        createExistingGroupTab();
        await waitForPromises();
      });

      it('lists the owned groups as options', () => {
        expect(findParentListbox().props('loading')).toBe(false);
        expect(findParentListbox().props('items')).toEqual([
          { value: 'flight', text: 'Flight' },
          { value: 'space', text: 'Space' },
          { value: 'sunny', text: 'Sunny' },
        ]);
      });

      it('shows the selected parent', () => {
        expect(findParentListbox().props('selected')).toBe('flight');
        expect(findParentListbox().props('toggleText')).toBe('Flight');
      });

      it('emits the whole selected group when a parent is chosen', () => {
        findParentListbox().vm.$emit('select', 'space');

        expect(wrapper.emitted('destination-input')).toEqual([
          [{ type: existingGroup, parentGroup: spaceGroup }],
        ]);
      });

      it('and then changes to top-level clears the parent group', () => {
        findTopLevelRadio().vm.$emit('change', topLevel);

        expect(wrapper.emitted('destination-input')).toEqual([
          [{ type: topLevel, parentGroup: null }],
        ]);
      });
    });
  });

  describe('when no parent is selected yet', () => {
    beforeEach(async () => {
      createComponent({
        propsData: { destinationSelection: { type: existingGroup, parentGroup: null } },
      });
      await waitForPromises();
    });

    it('prompts the user to pick a group', () => {
      expect(findParentListbox().props('selected')).toBe(null);
      expect(findParentListbox().props('toggleText')).toBe('Select a group');
    });
  });

  describe('when the user owns no groups', () => {
    beforeEach(async () => {
      createComponent({
        propsData: { destinationSelection: existingGroupValue },
        handler: jest.fn().mockResolvedValue(emptyGroupsResponse),
      });
      await waitForPromises();
    });

    it('informs user no groups exist', () => {
      expect(findParentGroupWrapper().exists()).toBe(false);
      expect(findNoOwnedGroupsAlert().text()).toContain('You do not own any groups');
    });
  });

  describe('when the groups query fails', () => {
    const queryError = new Error('network error');
    let handler;

    beforeEach(async () => {
      handler = jest.fn().mockRejectedValue(queryError);
      createComponent({ propsData: { destinationSelection: existingGroupValue }, handler });
      await waitForPromises();
    });

    it('shows a retryable error instead of the listbox', () => {
      expect(findFetchError().text()).toContain('Could not load your groups.');
      expect(findParentGroupWrapper().exists()).toBe(false);
    });

    it('reports the error to Sentry', () => {
      expect(captureException).toHaveBeenCalledWith(queryError);
    });

    it('refetches when the user retries', async () => {
      handler.mockResolvedValue(mockGroupsResponse);

      findFetchError().vm.$emit('primary-action');
      await waitForPromises();

      expect(handler).toHaveBeenCalledTimes(2);
      expect(findParentListbox().props('items')).toHaveLength(mockGroups.length);
    });

    it('clears the error when a later fetch succeeds', async () => {
      handler.mockResolvedValue(mockGroupsResponse);

      await wrapper.setProps({ destinationSelection: { type: topLevel, parentGroup: null } });
      await wrapper.setProps({ destinationSelection: existingGroupValue });
      await waitForPromises();

      expect(findFetchError().exists()).toBe(false);
      expect(findParentListbox().props('items')).toHaveLength(mockGroups.length);
    });
  });

  describe('pagination', () => {
    const createPaginated = async () => {
      const handler = jest
        .fn()
        .mockResolvedValueOnce(mockGroupsPage1Response)
        .mockResolvedValueOnce(mockGroupsPage2Response);

      createComponent({ propsData: { destinationSelection: existingGroupValue }, handler });
      await waitForPromises();

      return handler;
    };

    it('enables infinite scroll only once the first page has arrived', async () => {
      createComponent({
        propsData: { destinationSelection: existingGroupValue },
        handler: jest.fn().mockResolvedValue(mockGroupsPage1Response),
      });

      expect(findParentListbox().props('infiniteScroll')).toBe(false);

      await waitForPromises();

      expect(findParentListbox().props('infiniteScroll')).toBe(true);
    });

    it('appends the next page to the existing options', async () => {
      await createPaginated();
      expect(findParentListbox().props('items')).toHaveLength(3);

      findParentListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(findParentListbox().props('items')).toHaveLength(6);
      expect(findParentListbox().props('items').at(-1)).toEqual({
        value: 'orbit',
        text: 'Orbit',
      });
    });

    it('shows a spinner in the dropdown list, not on the dropdown toggle button', async () => {
      await createPaginated();

      findParentListbox().vm.$emit('bottom-reached');
      await nextTick();

      expect(findParentListbox().props('loading')).toBe(false);
      expect(findParentListbox().props('infiniteScrollLoading')).toBe(true);
    });

    it('requests the next page with the end cursor', async () => {
      const handler = await createPaginated();

      findParentListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(handler).toHaveBeenLastCalledWith(
        expect.objectContaining({ after: 'page-1-end-cursor' }),
      );
    });

    it('ignores a second bottom-reached while a page is already in flight', async () => {
      const handler = await createPaginated();

      findParentListbox().vm.$emit('bottom-reached');
      findParentListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(handler).toHaveBeenCalledTimes(2);
    });

    it('does not request more once the last page is loaded', async () => {
      const handler = await createPaginated();

      findParentListbox().vm.$emit('bottom-reached');
      await waitForPromises();
      expect(handler).toHaveBeenCalledTimes(2);

      findParentListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(handler).toHaveBeenCalledTimes(2);
    });
  });

  describe('when validation has been attempted', () => {
    it('marks a missing parent group as invalid', async () => {
      createComponent({
        propsData: {
          destinationSelection: { type: existingGroup, parentGroup: null },
          validationAttempted: true,
        },
      });
      await waitForPromises();

      expect(findParentListbox().props('state')).toBe(false);
    });

    it('leaves a chosen parent group valid', async () => {
      createComponent({
        propsData: { destinationSelection: existingGroupValue, validationAttempted: true },
      });
      await waitForPromises();

      expect(findParentListbox().props('state')).toBe(null);
    });
  });
});
