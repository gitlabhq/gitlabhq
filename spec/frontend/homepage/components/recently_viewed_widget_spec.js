import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RecentlyViewedWidget from '~/homepage/components/recently_viewed_widget.vue';

describe('RecentlyViewedWidget', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(RecentlyViewedWidget);
  };

  it('shows an empty state message', () => {
    createComponent();

    expect(wrapper.text()).toContain('Issues and merge requests you visit will appear here.');
  });
});
