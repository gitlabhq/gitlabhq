import { shallowMount } from '@vue/test-utils';
import ReviewBar from '~/batch_comments/components/review_bar.vue';
import { REVIEW_BAR_VISIBLE_CLASS_NAME } from '~/batch_comments/constants';
import createStore from '../create_batch_comments_store';

describe('Batch comments review bar component', () => {
  let store;
  let wrapper;
  let addEventListenerSpy;
  let removeEventListenerSpy;

  const createComponent = (propsData = {}) => {
    store = createStore();

    wrapper = shallowMount(ReviewBar, {
      store,
      propsData,
    });
  };

  beforeEach(() => {
    document.body.className = '';

    addEventListenerSpy = jest.spyOn(window, 'addEventListener');
    removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');
  });

  afterEach(() => {
    addEventListenerSpy.mockRestore();
    removeEventListenerSpy.mockRestore();
    wrapper.destroy();
  });

  describe('when mounted', () => {
    it('it adds review-bar-visible class to body', async () => {
      expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(false);

      createComponent();

      expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(true);
    });

    it('it adds a blocking handler to the `beforeunload` window event', () => {
      expect(addEventListenerSpy).not.toBeCalled();

      createComponent();

      expect(addEventListenerSpy).toHaveBeenCalledTimes(1);
      expect(addEventListenerSpy).toBeCalledWith('beforeunload', expect.any(Function), {
        capture: true,
      });
    });
  });

  describe('before destroyed', () => {
    it('it removes review-bar-visible class to body', async () => {
      createComponent();

      wrapper.destroy();

      expect(document.body.classList.contains(REVIEW_BAR_VISIBLE_CLASS_NAME)).toBe(false);
    });

    it('it removes the blocking handler from the `beforeunload` window event', () => {
      createComponent();

      expect(removeEventListenerSpy).not.toBeCalled();

      wrapper.destroy();

      expect(removeEventListenerSpy).toHaveBeenCalledTimes(1);
      expect(removeEventListenerSpy).toBeCalledWith('beforeunload', expect.any(Function), {
        capture: true,
      });
    });
  });
});
