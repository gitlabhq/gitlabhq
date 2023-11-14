import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerListHeader from '~/ci/runner/components/runner_list_header.vue';

describe('RunnerListHeader', () => {
  let wrapper;
  const createWrapper = (options) => {
    wrapper = shallowMountExtended(RunnerListHeader, {
      ...options,
    });
  };

  it('shows title', () => {
    createWrapper({
      scopedSlots: {
        title: () => 'My title',
      },
    });

    expect(wrapper.find('h1').text()).toBe('My title');
  });

  it('shows actions', () => {
    createWrapper({
      scopedSlots: {
        actions: () => 'My actions',
      },
    });

    expect(wrapper.text()).toContain('My actions');
  });
});
