import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';
import {
  HTTP_STATUS_CREATED,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
  HTTP_STATUS_TOO_MANY_REQUESTS,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';
import OfflineTransferExportApp from '~/import/offline_transfer/export/app.vue';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import SelectGroupsTab from '~/import/offline_transfer/export/select_groups_tab.vue';
import ExportConfigTab from '~/import/offline_transfer/export/export_config_tab.vue';
import ReviewExportTab from '~/import/offline_transfer/export/review_export_tab.vue';
import offlineTransferSourceOwnedGroupsQuery from '~/import/offline_transfer/graphql/queries/offline_transfer_source_owned_groups.query.graphql';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import { OFFLINE_EXPORT_TAB_HEADINGS } from '~/import/offline_transfer/constants';
import {
  mockGroups,
  mockGroupsResponse,
  mockGroupsPage1Response,
  mockGroupsPage2Response,
  emptyGroupsResponse,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/sentry/sentry_browser_wrapper');

describe('OfflineTransferExportApp', () => {
  let wrapper;

  const defaultHandler = jest.fn().mockResolvedValue(mockGroupsResponse);

  const createComponent = ({ handler = defaultHandler } = {}) => {
    const apolloProvider = createMockApollo([[offlineTransferSourceOwnedGroupsQuery, handler]]);

    wrapper = shallowMountExtended(OfflineTransferExportApp, { apolloProvider });
  };

  const findFormStepper = () => wrapper.findComponent(FormStepper);
  const findSelectGroupsTab = () => wrapper.findComponent(SelectGroupsTab);
  const findExportConfigTab = () => wrapper.findComponent(ExportConfigTab);
  const findReviewExportTab = () => wrapper.findComponent(ReviewExportTab);

  const queryError = new Error('query failed');
  const failingHandler = () => jest.fn().mockRejectedValue(queryError);
  const emptyHandler = () => jest.fn().mockResolvedValue(emptyGroupsResponse);

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

    describe('canStart', () => {
      it('as false when the user has no groups', async () => {
        createComponent({ handler: emptyHandler() });
        await waitForPromises();

        expect(findFormStepper().props('canStart')).toBe(false);
      });

      it('as false when there is a fetch error', async () => {
        createComponent({ handler: failingHandler() });
        await waitForPromises();

        expect(findFormStepper().props('canStart')).toBe(false);
      });

      it('as true while a search is active, even with no matches', async () => {
        createComponent({ handler: emptyHandler() });
        await waitForPromises();
        expect(findFormStepper().props('canStart')).toBe(false);

        findSelectGroupsTab().vm.$emit('search', 'no match');
        await waitForPromises();

        expect(findFormStepper().props('canStart')).toBe(true);
      });

      it('as true when groups are selected, even if a later fetch fails', async () => {
        const handler = jest
          .fn()
          .mockResolvedValueOnce(mockGroupsResponse)
          .mockRejectedValue(queryError);
        createComponent({ handler });
        await waitForPromises();

        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();

        findSelectGroupsTab().vm.$emit('search', 'triggers a failing refetch');
        await waitForPromises();
        expect(findSelectGroupsTab().props('hasFetchError')).toBe(true);

        expect(findFormStepper().props('canStart')).toBe(true);
      });
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('when `stepped-back` emitted clears previous step validation error', async () => {
      await findFormStepper().vm.$emit('validation-failed', 1);
      expect(findExportConfigTab().props('validationAttempted')).toBe(true);

      await findFormStepper().vm.$emit('stepped-back', { previousTabIndex: 1 });
      expect(findExportConfigTab().props('validationAttempted')).toBe(false);
    });
  });

  describe('Select Groups tab', () => {
    it('receives groups returned by the query', async () => {
      createComponent();
      await waitForPromises();

      expect(
        findSelectGroupsTab()
          .props('currentPageGroups')
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

    it('receives hasFetchError as false by default', () => {
      createComponent();
      expect(findSelectGroupsTab().props('hasFetchError')).toBe(false);
    });

    it('passes hasFetchError when the groups query fails', async () => {
      createComponent({ handler: failingHandler() });
      await waitForPromises();

      expect(findSelectGroupsTab().props('hasFetchError')).toBe(true);
    });

    it('reports the error to Sentry when the groups query fails', async () => {
      createComponent({ handler: failingHandler() });
      await waitForPromises();

      expect(captureException).toHaveBeenCalledWith(queryError);
    });

    it('re-runs the query when the tab emits retry-fetch', async () => {
      const handler = jest
        .fn()
        .mockRejectedValueOnce(queryError)
        .mockResolvedValue(mockGroupsResponse);
      createComponent({ handler });
      await waitForPromises();
      expect(findSelectGroupsTab().props('hasFetchError')).toBe(true);

      findSelectGroupsTab().vm.$emit('retry-fetch');
      await waitForPromises();

      expect(handler).toHaveBeenCalledTimes(2);
      expect(findSelectGroupsTab().props('hasFetchError')).toBe(false);
      expect(findSelectGroupsTab().props('currentPageGroups')).toHaveLength(3);
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
            .props('currentPageGroups')
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

    describe('form validation', () => {
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

  describe('Review export tab', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('passes the selected groups down to the tab', async () => {
      findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
      findSelectGroupsTab().vm.$emit('toggle', mockGroups[1]);
      await nextTick();

      expect(findReviewExportTab().props('selectedGroups')).toEqual([mockGroups[0], mockGroups[1]]);
    });

    it('always passes validation since the step has no action to validate', () => {
      expect(findFormStepper().props('validateStep')(2)).toBe(true);
    });
  });

  describe('form submission', () => {
    let mock;

    const submitUrl = buildApiUrl('/api/:version/offline_exports');
    const storageConfig = {
      accessKeyId: ' access-key ',
      secretAccessKey: 'secret-key',
      region: 'us-east-1 ',
      bucketName: 'my-bucket',
      pathStyle: true,
    };

    const submitForm = async () => {
      findFormStepper().vm.$emit('complete');
      await waitForPromises();
    };

    beforeEach(async () => {
      mock = new MockAdapter(axios);
      createComponent();
      await waitForPromises();

      findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
      findExportConfigTab().vm.$emit('input', storageConfig);
    });

    afterEach(() => {
      mock.restore();
    });

    it('POSTs the correct payload', async () => {
      mock.onPost(submitUrl).reply(HTTP_STATUS_CREATED, {});

      await submitForm();

      expect(JSON.parse(mock.history.post[0].data)).toEqual({
        bucket: 'my-bucket',
        aws_s3_configuration: {
          aws_access_key_id: 'access-key',
          aws_secret_access_key: 'secret-key',
          region: 'us-east-1',
          path_style: true,
        },
        entities: [{ full_path: mockGroups[0].fullPath }],
      });
    });

    it('marks the isSubmitting as true only while the request is pending', async () => {
      mock.onPost(submitUrl).reply(HTTP_STATUS_CREATED, {});

      findFormStepper().vm.$emit('complete');
      await nextTick();
      expect(findFormStepper().props('isSubmitting')).toBe(true);

      await waitForPromises();
      expect(findFormStepper().props('isSubmitting')).toBe(false);
    });

    describe('when the export starts (201)', () => {
      beforeEach(async () => {
        mock.onPost(submitUrl).reply(HTTP_STATUS_CREATED, {});
        await submitForm();
      });

      it('marks the submission as succeeded', () => {
        expect(findReviewExportTab().props('hasSubmitSucceeded')).toBe(true);
        expect(findReviewExportTab().props('submissionError')).toBe('');
        expect(findFormStepper().props('isFormComplete')).toBe(true);
      });
    });

    describe('when the server rejects with 422', () => {
      const serverMessage = 'Unable to access object storage bucket.';

      beforeEach(async () => {
        mock.onPost(submitUrl).reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, {
          message: serverMessage,
        });
        await submitForm();
      });

      it('shows the server message and blocks retry', () => {
        expect(findReviewExportTab().props('submissionError')).toBe(serverMessage);
        expect(findFormStepper().props('isCompletionDisabled')).toBe(true);
        expect(findReviewExportTab().props('hasSubmitSucceeded')).toBe(false);
      });

      it('does not report the failure to Sentry', () => {
        expect(captureException).not.toHaveBeenCalled();
      });

      it('clears the error and unblocks retry when the user goes back', async () => {
        await findFormStepper().vm.$emit('stepped-back', { previousTabIndex: 2 });

        expect(findReviewExportTab().props('submissionError')).toBe('');
        expect(findFormStepper().props('isCompletionDisabled')).toBe(false);
      });
    });

    describe('when server responds with the rate limit 429', () => {
      const rateLimitMessage = 'This endpoint has been requested too many times. Try again later.';

      beforeEach(async () => {
        mock.onPost(submitUrl).reply(HTTP_STATUS_TOO_MANY_REQUESTS, {
          message: { error: rateLimitMessage },
        });
        await submitForm();
      });

      it('shows the server message and blocks retry', () => {
        expect(findReviewExportTab().props('submissionError')).toBe(rateLimitMessage);
        expect(findFormStepper().props('isCompletionDisabled')).toBe(true);
      });

      it('does not report the failure to Sentry', () => {
        expect(captureException).not.toHaveBeenCalled();
      });

      it('clears the error and unblocks retry when the user goes back', async () => {
        await findFormStepper().vm.$emit('stepped-back', { previousTabIndex: 2 });

        expect(findReviewExportTab().props('submissionError')).toBe('');
        expect(findFormStepper().props('isCompletionDisabled')).toBe(false);
      });
    });

    describe('when the failure is unrecognized (500)', () => {
      beforeEach(async () => {
        mock.onPost(submitUrl).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        await submitForm();
      });

      it('shows the generic error and keeps retry available', () => {
        expect(findReviewExportTab().props('submissionError')).toBe(
          'Something went wrong. Try again later.',
        );
        expect(findFormStepper().props('isCompletionDisabled')).toBe(false);
      });

      it('reports the failure to Sentry', () => {
        expect(captureException).toHaveBeenCalled();
      });

      it('clears the error when a retry succeeds', async () => {
        expect(findReviewExportTab().props('submissionError')).not.toBe('');

        mock.reset();
        mock.onPost(submitUrl).reply(HTTP_STATUS_CREATED, {});
        await submitForm();

        expect(findReviewExportTab().props('submissionError')).toBe('');
        expect(findReviewExportTab().props('hasSubmitSucceeded')).toBe(true);
      });
    });

    describe('when a rejection carries no readable message', () => {
      beforeEach(async () => {
        mock.onPost(submitUrl).reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, {});
        await submitForm();
      });

      it('falls back to the generic error and keeps retry available', () => {
        expect(findReviewExportTab().props('submissionError')).toBe(
          'Something went wrong. Try again later.',
        );
        expect(findFormStepper().props('isCompletionDisabled')).toBe(false);
      });

      it('reports the failure to Sentry', () => {
        expect(captureException).toHaveBeenCalled();
      });
    });
  });
});
