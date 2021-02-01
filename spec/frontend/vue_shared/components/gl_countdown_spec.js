import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

describe('GlCountdown', () => {
  const Component = Vue.extend(GlCountdown);
  let vm;
  let now = '2000-01-01T00:00:00Z';

  beforeEach(() => {
    jest.spyOn(Date, 'now').mockImplementation(() => new Date(now).getTime());
  });

  afterEach(() => {
    vm.$destroy();
    jest.clearAllTimers();
  });

  describe('when there is time remaining', () => {
    beforeEach((done) => {
      vm = mountComponent(Component, {
        endDateString: '2000-01-01T01:02:03Z',
      });

      Vue.nextTick().then(done).catch(done.fail);
    });

    it('displays remaining time', () => {
      expect(vm.$el.textContent).toContain('01:02:03');
    });

    it('updates remaining time', (done) => {
      now = '2000-01-01T00:00:01Z';
      jest.advanceTimersByTime(1000);

      Vue.nextTick()
        .then(() => {
          expect(vm.$el.textContent).toContain('01:02:02');
          done();
        })
        .catch(done.fail);
    });
  });

  describe('when there is no time remaining', () => {
    beforeEach((done) => {
      vm = mountComponent(Component, {
        endDateString: '1900-01-01T00:00:00Z',
      });

      Vue.nextTick().then(done).catch(done.fail);
    });

    it('displays 00:00:00', () => {
      expect(vm.$el.textContent).toContain('00:00:00');
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
      vm = mountComponent(Component, {
        endDateString: 'this is invalid',
      });

      expect(Vue.config.warnHandler).toHaveBeenCalledTimes(1);
      const [errorMessage] = Vue.config.warnHandler.mock.calls[0];

      expect(errorMessage).toMatch(/^Invalid prop: .* "endDateString"/);
    });
  });
});
