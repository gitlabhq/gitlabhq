import { shallowMount } from '@vue/test-utils';
import ReviewBar from '~/batch_comments/components/review_bar.vue';
import { REVIEW_BAR_VISIBLE_CLASS_NAME } from '~/batch_comments/constants';
import createStore from '../create_batch_comments_store';

describe('Batch comments review bar component', () => {
  let store;
  let wrapper;

  const createComponent = (propsData = {}) => {
    store = createStore();

    wrapper = shallowMount(ReviewBar, {
      store,
      propsData,
    });
  };

  beforeEach(() => {
    document.body.className = '';
  });

  it('adds review-bar-visible class to body when review bar is mounted', () => {
    expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(false);

    createComponent();

    expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(true);
  });

  it('removes review-bar-visible class to body when review bar is destroyed', () => {
    createComponent();

    wrapper.destroy();

    expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(false);
  });
});
