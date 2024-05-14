import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TimeAgo from '~/ci/pipelines_page/components/time_ago.vue';

describe('Timeago component', () => {
  let wrapper;

  const defaultProps = { duration: 0, finished_at: '' };

  const createComponent = (props = defaultProps, extraProps) => {
    wrapper = extendedWrapper(
      shallowMount(TimeAgo, {
        propsData: {
          pipeline: {
            details: {
              ...props,
            },
          },
          ...extraProps,
        },
        data() {
          return {
            iconTimerSvg: `<svg></svg>`,
          };
        },
      }),
    );
  };

  const duration = () => wrapper.find('[data-testid="duration"]');
  const finishedAt = () => wrapper.find('[data-testid="finished-at"]');
  const findCalendarIcon = () => wrapper.findByTestId('calendar-icon');

  describe('with duration', () => {
    beforeEach(() => {
      createComponent({ duration: 10, finished_at: '' });
    });

    it('should render duration and timer svg', () => {
      const icon = duration().findComponent(GlIcon);

      expect(duration().exists()).toBe(true);
      expect(icon.props('name')).toBe('timer');
    });
  });

  describe('without duration', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not render duration and timer svg', () => {
      expect(duration().exists()).toBe(false);
    });
  });

  describe('with finishedTime', () => {
    it('should render time', () => {
      createComponent({ duration: 0, finished_at: '2017-04-26T12:40:23.277Z' });

      const time = finishedAt().find('time');

      expect(finishedAt().exists()).toBe(true);
      expect(time.exists()).toBe(true);
    });

    it('should display calendar icon', () => {
      createComponent({ duration: 0, finished_at: '2017-04-26T12:40:23.277Z' });

      expect(findCalendarIcon().exists()).toBe(true);
    });
  });

  describe('without finishedTime', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should not render time and calendar icon', () => {
      expect(finishedAt().exists()).toBe(false);
      expect(findCalendarIcon().exists()).toBe(false);
    });
  });
});
