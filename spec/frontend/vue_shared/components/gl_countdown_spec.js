import Vue, { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

describe('GlCountdown', () => {
  let wrapper;
  let now = '2000-01-01T00:00:00Z';

  beforeEach(() => {
    jest.spyOn(Date, 'now').mockImplementation(() => new Date(now).getTime());
  });

  describe('when there is time remaining', () => {
    beforeEach(() => {
      wrapper = mount(GlCountdown, {
        propsData: {
          endDateString: '2000-01-01T01:02:03Z',
        },
      });
    });

    it('displays remaining time', () => {
      expect(wrapper.text()).toContain('01:02:03');
    });

    it('updates remaining time', async () => {
      now = '2000-01-01T00:00:01Z';
      jest.advanceTimersByTime(1000);

      await nextTick();
      expect(wrapper.text()).toContain('01:02:02');
    });
  });

  describe('when there is no time remaining', () => {
    beforeEach(() => {
      wrapper = mount(GlCountdown, {
        propsData: {
          endDateString: '1900-01-01T00:00:00Z',
        },
      });
    });

    it('displays 00:00:00', () => {
      expect(wrapper.text()).toContain('00:00:00');
    });

    it('emits `timer-expired` event', () => {
      expect(wrapper.emitted('timer-expired')).toStrictEqual([[]]);
    });
  });

  describe('when an invalid date is passed', () => {
    beforeEach(() => {
      Vue.config.warnHandler = jest.fn();
    });

    afterEach(() => {
      Vue.config.warnHandler = null;
    });

    it('throws a validation error', () => {
      wrapper = mount(GlCountdown, {
        propsData: {
          endDateString: 'this is invalid',
        },
      });

      expect(Vue.config.warnHandler).toHaveBeenCalledTimes(1);
      const [errorMessage] = Vue.config.warnHandler.mock.calls[0];

      expect(errorMessage).toMatch(/^Invalid prop: .* "endDateString"/);
    });
  });
});
