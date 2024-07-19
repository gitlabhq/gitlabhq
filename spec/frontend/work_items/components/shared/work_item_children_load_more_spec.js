import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WorkItemChildrenLoadMore from '~/work_items/components/shared/work_item_children_load_more.vue';

describe('WorkItemChildrenLoadMore', () => {
  let wrapper;
  const findLoadMoreButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const createComponent = (fetchNextPageInProgress = false) => {
    wrapper = shallowMountExtended(WorkItemChildrenLoadMore, {
      propsData: {
        fetchNextPageInProgress,
      },
    });
  };

  it('renders "Load more" button when fetchNextPageInProgress is false', () => {
    createComponent();

    const button = findLoadMoreButton();
    expect(button.exists()).toBe(true);
    expect(button.text()).toBe('Load more');
  });

  it('renders loading icon when fetchNextPageInProgress is true', () => {
    createComponent(true);

    const loadingIcon = findLoadingIcon();
    expect(loadingIcon.exists()).toBe(true);
  });
});
