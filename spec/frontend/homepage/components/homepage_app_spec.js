import { shallowMount } from '@vue/test-utils';
import HomepageApp from '~/homepage/components/homepage_app.vue';
import MergeRequestsWidget from '~/homepage/components/merge_requests_widget.vue';

describe('HomepageApp', () => {
  const MOCK_REVIEW_REQUESTED_PATH = '/review/requested/path';
  const MOCK_ASSIGNED_TO_YOU_PATH = '/assigned/to/you/path';

  let wrapper;

  const findMergeRequestsWidget = () => wrapper.findComponent(MergeRequestsWidget);

  function createWrapper() {
    wrapper = shallowMount(HomepageApp, {
      propsData: {
        reviewRequestedPath: MOCK_REVIEW_REQUESTED_PATH,
        assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
      },
    });
  }

  beforeEach(() => {
    createWrapper();
  });

  it('passes the correct props to the `MergeRequestsWidget` component', () => {
    expect(findMergeRequestsWidget().props()).toEqual({
      reviewRequestedPath: MOCK_REVIEW_REQUESTED_PATH,
      assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
    });
  });
});
