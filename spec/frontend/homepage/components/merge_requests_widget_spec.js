import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import MergeRequestsWidget from '~/homepage/components/merge_requests_widget.vue';

describe('MergeRequestsWidget', () => {
  const MOCK_REVIEW_REQUESTED_PATH = '/review/requested/path';
  const MOCK_ASSIGNED_TO_YOU_PATH = '/assigned/to/you/path';

  let wrapper;

  const findGlLinks = () => wrapper.findAllComponents(GlLink);

  function createWrapper() {
    wrapper = shallowMount(MergeRequestsWidget, {
      propsData: {
        reviewRequestedPath: MOCK_REVIEW_REQUESTED_PATH,
        assignedToYouPath: MOCK_ASSIGNED_TO_YOU_PATH,
      },
    });
  }

  beforeEach(() => {
    createWrapper();
  });

  it('renders the "Review requested" link', () => {
    expect(findGlLinks().at(0).props('href')).toBe(MOCK_REVIEW_REQUESTED_PATH);
  });

  it('renders the "Assigned to you" link', () => {
    expect(findGlLinks().at(1).props('href')).toBe(MOCK_ASSIGNED_TO_YOU_PATH);
  });
});
