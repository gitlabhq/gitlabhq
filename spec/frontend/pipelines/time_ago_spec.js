import { shallowMount } from '@vue/test-utils';
import TimeAgo from '~/pipelines/components/time_ago.vue';

describe('Timeago component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(TimeAgo, {
      propsData: {
        ...props,
      },
      data() {
        return {
          iconTimerSvg: `<svg></svg>`,
        };
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with duration', () => {
    beforeEach(() => {
      createComponent({ duration: 10, finishedTime: '' });
    });

    it('should render duration and timer svg', () => {
      expect(wrapper.find('.duration').exists()).toBe(true);
      expect(wrapper.find('.duration svg').exists()).toBe(true);
    });
  });

  describe('without duration', () => {
    beforeEach(() => {
      createComponent({ duration: 0, finishedTime: '' });
    });

    it('should not render duration and timer svg', () => {
      expect(wrapper.find('.duration').exists()).toBe(false);
    });
  });

  describe('with finishedTime', () => {
    beforeEach(() => {
      createComponent({ duration: 0, finishedTime: '2017-04-26T12:40:23.277Z' });
    });

    it('should render time and calendar icon', () => {
      expect(wrapper.find('.finished-at').exists()).toBe(true);
      expect(wrapper.find('.finished-at i.fa-calendar').exists()).toBe(true);
      expect(wrapper.find('.finished-at time').exists()).toBe(true);
    });
  });

  describe('without finishedTime', () => {
    beforeEach(() => {
      createComponent({ duration: 0, finishedTime: '' });
    });

    it('should not render time and calendar icon', () => {
      expect(wrapper.find('.finished-at').exists()).toBe(false);
    });
  });
});
