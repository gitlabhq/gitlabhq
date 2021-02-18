import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ErrorTrackingActions from '~/error_tracking/components/error_tracking_actions.vue';

describe('Error Tracking Actions', () => {
  let wrapper;

  function mountComponent(props) {
    wrapper = shallowMount(ErrorTrackingActions, {
      propsData: {
        error: {
          id: '1',
          title: 'PG::ConnectionBad: FATAL',
          type: 'error',
          userCount: 0,
          count: '52',
          firstSeen: '2019-05-30T07:21:46Z',
          lastSeen: '2019-11-06T03:21:39Z',
          status: 'unresolved',
        },
        ...props,
      },
      stubs: { GlButton },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findButtons = () => wrapper.findAll(GlButton);

  describe('when error status is unresolved', () => {
    it('renders the correct actions buttons to allow ignore and resolve', () => {
      expect(findButtons().exists()).toBe(true);

      return wrapper.vm.$nextTick().then(() => {
        expect(findButtons().at(0).attributes('title')).toBe('Ignore');
        expect(findButtons().at(1).attributes('title')).toBe('Resolve');
      });
    });
  });

  describe('when error status is ignored', () => {
    beforeEach(() => {
      mountComponent({ error: { status: 'ignored' } });
    });

    it('renders the correct action button to undo ignore', () => {
      expect(findButtons().exists()).toBe(true);

      return wrapper.vm.$nextTick().then(() => {
        expect(findButtons().at(0).attributes('title')).toBe('Undo Ignore');
      });
    });
  });

  describe('when error status is resolved', () => {
    beforeEach(() => {
      mountComponent({ error: { status: 'resolved' } });
    });

    it('renders the correct action button to undo unresolve', () => {
      expect(findButtons().exists()).toBe(true);

      return wrapper.vm.$nextTick().then(() => {
        expect(findButtons().at(1).attributes('title')).toBe('Unresolve');
      });
    });
  });
});
