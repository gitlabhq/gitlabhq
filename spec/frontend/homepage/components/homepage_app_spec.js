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

  it('passes the correct props to the `MergeRequestsWidget` component', () => {
    expect(findMergeRequestsWidget().props()).toEqual({
      reviewRequestedPath: MOCK_MERGE_REQUESTS_REVIEW_REQUESTED_PATH,
      assignedToYouPath: MOCK_ASSIGNED_MERGE_REQUESTS_PATH,
    });
  });

  it('passes the correct props to the `WorkItemsWidget` component', () => {
    expect(findWorkItemsWidget().props()).toEqual({
      assignedToYouPath: MOCK_ASSIGNED_WORK_ITEMS_PATH,
      authoredByYouPath: MOCK_AUTHORED_WORK_ITEMS_PATH,
    });
  });
});
