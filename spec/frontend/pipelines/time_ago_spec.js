import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import TimeAgo from '~/pipelines/components/pipelines_list/time_ago.vue';

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

  const duration = () => wrapper.find('.duration');
  const finishedAt = () => wrapper.find('.finished-at');

  describe('with duration', () => {
    beforeEach(() => {
      createComponent({ duration: 10, finishedTime: '' });
    });

    it('should render duration and timer svg', () => {
      const icon = duration().find(GlIcon);

      expect(duration().exists()).toBe(true);
      expect(icon.props('name')).toBe('timer');
    });
  });

  describe('without duration', () => {
    beforeEach(() => {
      createComponent({ duration: 0, finishedTime: '' });
    });

    it('should not render duration and timer svg', () => {
      expect(duration().exists()).toBe(false);
    });
  });

  describe('with finishedTime', () => {
    beforeEach(() => {
      createComponent({ duration: 0, finishedTime: '2017-04-26T12:40:23.277Z' });
    });

    it('should render time and calendar icon', () => {
      const icon = finishedAt().find(GlIcon);
      const time = finishedAt().find('time');

      expect(finishedAt().exists()).toBe(true);
      expect(icon.props('name')).toBe('calendar');
      expect(time.exists()).toBe(true);
    });
  });

  describe('without finishedTime', () => {
    beforeEach(() => {
      createComponent({ duration: 0, finishedTime: '' });
    });

    it('should not render time and calendar icon', () => {
      expect(finishedAt().exists()).toBe(false);
    });
  });
});
