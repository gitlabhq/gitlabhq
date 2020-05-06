import { shallowMount } from '@vue/test-utils';
import AlertDetails from '~/alert_management/components/alert_details.vue';

describe('AlertDetails', () => {
  let wrapper;

  function mountComponent(alert = {}) {
    wrapper = shallowMount(AlertDetails, {
      propsData: {
        alertId: 'alertId',
        projectPath: 'projectPath',
      },
      data() {
        return { alert };
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('Alert details', () => {
    describe('when alert is null', () => {
      beforeEach(() => {
        mountComponent(null);
      });

      describe('when alert is null', () => {
        beforeEach(() => {
          mountComponent(null);
        });

        it('shows an empty state', () => {
          expect(wrapper.find('[data-testid="alertDetailsTabs"]').exists()).toBe(false);
        });
      });
    });

    describe('when alert is present', () => {
      beforeEach(() => {
        mountComponent();
      });

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

    it('renders a status dropdown containing three items', () => {
      expect(wrapper.findAll('[data-testid="statusDropdownItem"]').length).toBe(3);
    });
  });
});
