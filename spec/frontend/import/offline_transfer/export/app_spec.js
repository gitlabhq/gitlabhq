import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OfflineTransferExportApp from '~/import/offline_transfer/export/app.vue';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import SelectGroupsTab from '~/import/offline_transfer/export/select_groups_tab.vue';
import offlineTransferSourceOwnedGroupsQuery from '~/import/offline_transfer/graphql/queries/offline_transfer_source_owned_groups.query.graphql';
import { OFFLINE_EXPORT_TAB_HEADINGS } from '~/import/offline_transfer/constants';
import {
  mockGroups,
  mockGroupsResponse,
  mockGroupsPage1Response,
  mockGroupsPage2Response,
} from '../mock_data';

Vue.use(VueApollo);

describe('OfflineTransferExportApp', () => {
  let wrapper;

  const defaultHandler = jest.fn().mockResolvedValue(mockGroupsResponse);

  const createComponent = ({ handler = defaultHandler } = {}) => {
    const apolloProvider = createMockApollo([[offlineTransferSourceOwnedGroupsQuery, handler]]);

    wrapper = shallowMountExtended(OfflineTransferExportApp, { apolloProvider });
  };

  const findFormStepper = () => wrapper.findComponent(FormStepper);
  const findSelectGroupsTab = () => wrapper.findComponent(SelectGroupsTab);
  const findCompletionAlert = () => wrapper.findByTestId('completion-alert');
  const findValidationErrorAlert = () => wrapper.findByTestId('validation-alert');
  const findFetchErrorAlert = () => wrapper.findByTestId('fetch-error-alert');

  describe('passes to FormStepper', () => {
    beforeEach(() => {
      createComponent();
    });

    it('the correct steps', () => {
      expect(findFormStepper().props('steps')).toBe(OFFLINE_EXPORT_TAB_HEADINGS);
    });

    it('the correct completion button text', () => {
      expect(findFormStepper().props('completionButtonText')).toBe('Start export');
    });

    it('validateStep as a function', () => {
      expect(findFormStepper().props('validateStep')).toBeInstanceOf(Function);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('triggers a completion alert when FormStepper emits complete', async () => {
      expect(findCompletionAlert().exists()).toBe(false);

      await findFormStepper().vm.$emit('complete');

      expect(findCompletionAlert().exists()).toBe(true);
    });

    // TODO delete or replace test when all steps are added
    it('triggers a validation error alert when a step without inline errors fails', async () => {
      expect(findValidationErrorAlert().exists()).toBe(false);

      await findFormStepper().vm.$emit('validation-failed', 2);

      expect(findValidationErrorAlert().exists()).toBe(true);
    });

    it('clears the shared validation error alert when that step is passed (stepped-forward)', async () => {
      await findFormStepper().vm.$emit('validation-failed', 2);
      expect(findValidationErrorAlert().exists()).toBe(true);

      await findFormStepper().vm.$emit('stepped-forward', { previousTabIndex: 2 });
      expect(findValidationErrorAlert().exists()).toBe(false);
    });

    it('sets the previously completed step as invalid after FormStepper emits stepped-back', async () => {
      wrapper.vm.isStepComplete.export = true;
      expect(findFormStepper().props('validateStep')(2)).toBe(true);

      await findFormStepper().vm.$emit('stepped-back', {
        previousTabIndex: 2,
      });

      expect(findFormStepper().props('validateStep')(2)).toBe(false);
    });
  });

  describe('Select Groups tab', () => {
    it('receives groups returned by the query', async () => {
      createComponent();
      await waitForPromises();

      expect(
        findSelectGroupsTab()
          .props('pageGroups')
          .map((group) => group.id),
      ).toEqual(['gid://glab/Group/1', 'gid://glab/Group/2', 'gid://glab/Group/3']);
    });

    it('receives showSelectError as false by default', () => {
      createComponent();
      expect(findSelectGroupsTab().props('showSelectError')).toBe(false);
    });

    it('receives query loading state', async () => {
      createComponent();
      expect(findSelectGroupsTab().props('loading')).toBe(true);
      await waitForPromises();
      expect(findSelectGroupsTab().props('loading')).toBe(false);
    });

    it('receives initialLoading until the first response lands', async () => {
      createComponent();
      expect(findSelectGroupsTab().props('initialLoading')).toBe(true);
      await waitForPromises();
      expect(findSelectGroupsTab().props('initialLoading')).toBe(false);
    });

    it('shows the fetch error alert when groups query fails', async () => {
      createComponent({ handler: jest.fn().mockRejectedValue(new Error('query failed')) });
      await waitForPromises();

      expect(findFetchErrorAlert().exists()).toBe(true);
    });

    describe('selection', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('when emits `toggle`, adds a group to the selected collection', async () => {
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([mockGroups[0].id]);
      });

      it('when toggled again, removes group from the selection', async () => {
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([]);
      });

      it('when emits `select-current-page` adds every group', async () => {
        findSelectGroupsTab().vm.$emit('select-current-page');
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([
          'gid://glab/Group/1',
          'gid://glab/Group/2',
          'gid://glab/Group/3',
        ]);
      });

      it('when emits `deselect-all` empties the collection', async () => {
        findSelectGroupsTab().vm.$emit('select-current-page');
        await nextTick();
        findSelectGroupsTab().vm.$emit('deselect-all');
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([]);
      });
    });

    describe('pagination', () => {
      const PAGE_1_END_CURSOR = mockGroupsPage1Response.data.groups.pageInfo.endCursor;
      const PAGE_2_START_CURSOR = mockGroupsPage2Response.data.groups.pageInfo.startCursor;
      const PAGE_1_IDS = ['gid://glab/Group/1', 'gid://glab/Group/2', 'gid://glab/Group/3'];
      const PAGE_2_IDS = ['gid://glab/Group/4', 'gid://glab/Group/5', 'gid://glab/Group/6'];

      // Returns page 1 on the first query, page 2 on the second.
      const createPaginatedComponent = () => {
        const handler = jest
          .fn()
          .mockResolvedValueOnce(mockGroupsPage1Response)
          .mockResolvedValueOnce(mockGroupsPage2Response);
        createComponent({ handler });
        return handler;
      };

      it('passes pageInfo from the query down to the tab', async () => {
        createComponent();
        await waitForPromises();

        expect(findSelectGroupsTab().props('pageInfo')).toMatchObject(
          mockGroupsResponse.data.groups.pageInfo,
        );
      });

      it('fetches the next page with `after` when the tab emits next', async () => {
        const handler = createPaginatedComponent();
        await waitForPromises();

        findSelectGroupsTab().vm.$emit('next', PAGE_1_END_CURSOR);
        await waitForPromises();

        expect(handler).toHaveBeenLastCalledWith(
          expect.objectContaining({ after: PAGE_1_END_CURSOR, before: null }),
        );
        expect(
          findSelectGroupsTab()
            .props('pageGroups')
            .map((group) => group.id),
        ).toEqual(PAGE_2_IDS);
      });

      it('fetches the previous page with `before` when the tab emits prev', async () => {
        const handler = createPaginatedComponent();
        await waitForPromises();

        findSelectGroupsTab().vm.$emit('prev', PAGE_2_START_CURSOR);
        await waitForPromises();

        expect(handler).toHaveBeenLastCalledWith(
          expect.objectContaining({ before: PAGE_2_START_CURSOR, after: null }),
        );
      });

      it('keeps the selection when the page changes', async () => {
        createPaginatedComponent();
        await waitForPromises();

        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();

        findSelectGroupsTab().vm.$emit('next', PAGE_1_END_CURSOR);
        await waitForPromises();

        expect(findSelectGroupsTab().props('selectedIds')).toContain(mockGroups[0].id);
      });

      it('accumulates selections across pages on select-current-page', async () => {
        createPaginatedComponent();
        await waitForPromises();

        findSelectGroupsTab().vm.$emit('select-current-page');
        await nextTick();

        findSelectGroupsTab().vm.$emit('next', PAGE_1_END_CURSOR);
        await waitForPromises();

        findSelectGroupsTab().vm.$emit('select-current-page');
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([...PAGE_1_IDS, ...PAGE_2_IDS]);
      });
    });

    describe('when search changes', () => {
      const SEARCH_TERM = 'flight';

      it('re-runs the query with the new search', async () => {
        createComponent();
        expect(findSelectGroupsTab().props('searchTerm')).toBe('');

        findSelectGroupsTab().vm.$emit('search', SEARCH_TERM);
        await nextTick();

        expect(defaultHandler).toHaveBeenLastCalledWith(
          expect.objectContaining({ search: SEARCH_TERM }),
        );

        expect(findSelectGroupsTab().props('searchTerm')).toBe(SEARCH_TERM);
      });

      it('if the user is not on first page, resets pagination to the first page', async () => {
        const handler = jest
          .fn()
          .mockResolvedValueOnce(mockGroupsPage1Response)
          .mockResolvedValueOnce(mockGroupsPage2Response)
          .mockResolvedValue(mockGroupsResponse);
        createComponent({ handler });
        await waitForPromises();

        // navigate to the second page
        findSelectGroupsTab().vm.$emit(
          'next',
          mockGroupsPage1Response.data.groups.pageInfo.endCursor,
        );
        await waitForPromises();
        expect(handler).toHaveBeenLastCalledWith(
          expect.objectContaining({
            search: '',
            after: mockGroupsPage1Response.data.groups.pageInfo.endCursor,
            before: null,
            first: 20,
            last: null,
          }),
        );

        findSelectGroupsTab().vm.$emit('search', SEARCH_TERM);
        await waitForPromises();

        expect(handler).toHaveBeenLastCalledWith(
          expect.objectContaining({
            search: SEARCH_TERM,
            after: null,
            before: null,
            first: 20,
            last: null,
          }),
        );
      });

      it('preserves selections across a search', async () => {
        createComponent();
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[1]);
        await nextTick();
        expect(findSelectGroupsTab().props('selectedIds')).toEqual([
          mockGroups[0].id,
          mockGroups[1].id,
        ]);

        findSelectGroupsTab().vm.$emit('search', 'flight');
        expect(findSelectGroupsTab().props('selectedIds')).toEqual([
          mockGroups[0].id,
          mockGroups[1].id,
        ]);
      });
    });

    describe('validation', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('keeps Select Group step invalid while nothing is selected', () => {
        expect(findFormStepper().props('validateStep')(0)).toBe(false);
      });

      it('makes Select Group step valid once a group is selected', async () => {
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();

        expect(findFormStepper().props('validateStep')(0)).toBe(true);
      });

      it('clears existing showSelectError when the groups step is passed (stepped-forward)', async () => {
        await findFormStepper().vm.$emit('validation-failed', 0);
        expect(findSelectGroupsTab().props('showSelectError')).toBe(true);

        await findFormStepper().vm.$emit('stepped-forward', { previousTabIndex: 0 });
        expect(findSelectGroupsTab().props('showSelectError')).toBe(false);
      });

      it('after failed continue, when group selection changes, clears showSelectError', async () => {
        await findFormStepper().vm.$emit('validation-failed', 0);
        expect(findSelectGroupsTab().props('showSelectError')).toBe(true);

        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();
        expect(findSelectGroupsTab().props('showSelectError')).toBe(false);

        findSelectGroupsTab().vm.$emit('deselect-all');
        await nextTick();
        expect(findSelectGroupsTab().props('showSelectError')).toBe(false);
      });
    });
  });
});
