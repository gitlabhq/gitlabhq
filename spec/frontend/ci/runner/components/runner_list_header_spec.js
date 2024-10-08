import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerListHeader from '~/ci/runner/components/runner_list_header.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('RunnerListHeader', () => {
  let wrapper;
  const createWrapper = (options) => {
    wrapper = shallowMountExtended(RunnerListHeader, {
      ...options,
      stubs: {
        PageHeading,
      },
    });
  };

  const findPageHeading = () => wrapper.findByTestId('page-heading');
  const findPageHeadingDescription = () => wrapper.findByTestId('page-heading-description');
  const findPageHeadingActions = () => wrapper.findByTestId('page-heading-actions');

  it('shows title', () => {
    createWrapper({
      scopedSlots: {
        title: () => 'My title',
      },
    });

    expect(findPageHeading().text()).toBe('My title');
  });

  it('shows description', () => {
    createWrapper({
      scopedSlots: {
        description: () => 'My description',
      },
    });

    expect(findPageHeadingDescription().text()).toBe('My description');
  });

  it('shows actions', () => {
    createWrapper({
      scopedSlots: {
        actions: () => 'My actions',
      },
    });

    expect(findPageHeadingActions().text()).toBe('My actions');
  });
});
