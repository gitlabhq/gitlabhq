import { shallowMount } from '@vue/test-utils';
import AlertDetails from '~/alert_management/components/alert_details.vue';

describe('AlertDetails', () => {
  let wrapper;

  function mountComponent() {
    wrapper = shallowMount(AlertDetails);
  }

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('Alert details', () => {
    it('renders a tab with overview information', () => {
      expect(wrapper.find('[data-testid="overviewTab"]').exists()).toBe(true);
    });

    it('renders a tab with full alert information', () => {
      expect(wrapper.find('[data-testid="fullDetailsTab"]').exists()).toBe(true);
    });

    it('renders alert details', () => {
      expect(wrapper.find('[data-testid="startTimeItem"]').exists()).toBe(true);
    });
  });
});
