import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HomepageApp from '~/homepage/components/homepage_app.vue';
import MergeRequestsWidget from '~/homepage/components/merge_requests_widget.vue';
import WorkItemsWidget from '~/homepage/components/work_items_widget.vue';

describe('HomepageApp', () => {
  const MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_PATH = '/merge/requests/review/requested/path';
  const MOCK_ASSIGNED_MERGE_REQUESTS_PATH = '/merge/requests/assigned/to/you/path';
  const MOCK_ASSIGNED_WORK_ITEMS_PATH = '/work/items/assigned/to/you/path';
  const MOCK_AUTHORED_WORK_ITEMS_PATH = '/work/items/authored/to/you/path';

  let wrapper;

  const findMergeRequestsWidget = () => wrapper.findComponent(MergeRequestsWidget);
  const findWorkItemsWidget = () => wrapper.findComponent(WorkItemsWidget);
  const findMergeRequestsFetchMetadataError = () =>
    wrapper.findByTestId('merge-requests-fetch-metadata-error');
  const findWorkItemsFetchMetadataDesktopError = () =>
    wrapper.findByTestId('work-items-fetch-metadata-desktop-error');
  const findWorkItemsFetchMetadataMobileError = () =>
    wrapper.findByTestId('work-items-fetch-metadata-mobile-error');

  function createWrapper() {
    wrapper = shallowMountExtended(HomepageApp, {
      propsData: {
        reviewRequestedPath: MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_PATH,
        assignedMergeRequestsPath: MOCK_ASSIGNED_MERGE_REQUESTS_PATH,
        assignedWorkItemsPath: MOCK_ASSIGNED_WORK_ITEMS_PATH,
        authoredWorkItemsPath: MOCK_AUTHORED_WORK_ITEMS_PATH,
      },
    });
  }

  beforeEach(() => {
    createWrapper();
  });

  describe('MergeRequestsWidget', () => {
    it('passes the correct props to the `MergeRequestsWidget` component', () => {
      expect(findMergeRequestsWidget().props()).toEqual({
        reviewRequestedPath: MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_PATH,
        assignedToYouPath: MOCK_ASSIGNED_MERGE_REQUESTS_PATH,
      });
    });

    it('shows an alert if `MergeRequestsWidget` fails to fetch the metadata', async () => {
      expect(findMergeRequestsFetchMetadataError().exists()).toBe(false);

      findMergeRequestsWidget().vm.$emit('fetch-metadata-error');
      await nextTick();

      expect(findMergeRequestsFetchMetadataError().text()).toBe(
        'The number of merge requests is not available. Please refresh the page to try again.',
      );
    });

    it('hides the alert on dismiss', async () => {
      findMergeRequestsWidget().vm.$emit('fetch-metadata-error');
      await nextTick();
      findMergeRequestsFetchMetadataError().vm.$emit('dismiss');
      await nextTick();

      expect(findMergeRequestsFetchMetadataError().exists()).toBe(false);
    });
  });

  describe('WorkItemsWidget', () => {
    it('passes the correct props to the `WorkItemsWidget` component', () => {
      expect(findWorkItemsWidget().props()).toEqual({
        assignedToYouPath: MOCK_ASSIGNED_WORK_ITEMS_PATH,
        authoredByYouPath: MOCK_AUTHORED_WORK_ITEMS_PATH,
      });
    });

    it('shows an alert if `WorkItemsWidget` fails to fetch the metadata', async () => {
      expect(findWorkItemsFetchMetadataDesktopError().exists()).toBe(false);
      expect(findWorkItemsFetchMetadataMobileError().exists()).toBe(false);

      findWorkItemsWidget().vm.$emit('fetch-metadata-error');
      await nextTick();

      expect(findWorkItemsFetchMetadataDesktopError().text()).toBe(
        'The number of issues is not available. Please refresh the page to try again.',
      );
      expect(findWorkItemsFetchMetadataMobileError().text()).toBe(
        'The number of issues is not available. Please refresh the page to try again.',
      );
    });

    it.each([findWorkItemsFetchMetadataDesktopError, findWorkItemsFetchMetadataMobileError])(
      'hides the alert on dismiss',
      async (alertFinder) => {
        findWorkItemsWidget().vm.$emit('fetch-metadata-error');
        await nextTick();
        alertFinder().vm.$emit('dismiss');
        await nextTick();

        expect(findWorkItemsFetchMetadataDesktopError().exists()).toBe(false);
        expect(findWorkItemsFetchMetadataMobileError().exists()).toBe(false);
      },
    );
  });
});
