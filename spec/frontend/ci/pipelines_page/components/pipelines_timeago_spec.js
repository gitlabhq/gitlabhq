import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelinesTimeago from '~/ci/pipelines_page/components/pipelines_timeago.vue';

describe('PipelinesTimeago component', () => {
  let wrapper;

  const createComponent = (pipeline = {}) => {
    wrapper = shallowMountExtended(PipelinesTimeago, {
      propsData: {
        pipeline,
      },
    });
  };

  const findDuration = () => wrapper.findByTestId('duration');
  const findFinishedAt = () => wrapper.findByTestId('finished-at');

  describe('with duration', () => {
    beforeEach(() => {
      createComponent({ details: { duration: 10, finished_at: '' } });
    });

    it('should render duration and timer icon', () => {
      expect(findDuration().findComponent(GlIcon).props('name')).toBe('timer');
      expect(findDuration().text()).toBe('00:00:10');
    });
  });

  describe('with duration equal to 0', () => {
    beforeEach(() => {
      createComponent({ details: { duration: 0, finished_at: '' } });
    });

    it('should render duration and timer icon', () => {
      expect(findDuration().findComponent(GlIcon).props('name')).toBe('timer');
      expect(findDuration().text()).toBe('00:00:00');
    });
  });

  describe('without duration', () => {
    beforeEach(() => {
      createComponent({ details: { duration: null, finished_at: '' } });
    });

    it('should not render duration and timer svg', () => {
      expect(findDuration().exists()).toBe(false);
    });
  });

  describe('with finishedTime', () => {
    it('should render time', () => {
      createComponent({ details: { duration: 0, finished_at: '2020-07-05T23:00:00Z' } });

      expect(findFinishedAt().findComponent(GlIcon).props('name')).toBe('calendar');
      expect(findFinishedAt().find('time').text()).toBe('1 hour ago');
    });
  });

  describe('with finishedTime directly in the pipeline', () => {
    it('should render time', () => {
      createComponent({ finishedAt: '2020-07-05T23:00:00Z' });

      expect(findFinishedAt().findComponent(GlIcon).props('name')).toBe('calendar');
      expect(findFinishedAt().find('time').text()).toBe('1 hour ago');
    });
  });

  describe('without finishedTime', () => {
    beforeEach(() => {
      createComponent({ details: { duration: 0, finished_at: '' } });
    });

    it('should not render time and calendar icon', () => {
      expect(findFinishedAt().exists()).toBe(false);
    });
  });

  describe('with no data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not render time and calendar icon', () => {
      expect(findDuration().exists()).toBe(false);
      expect(findFinishedAt().exists()).toBe(false);
    });
  });
});
