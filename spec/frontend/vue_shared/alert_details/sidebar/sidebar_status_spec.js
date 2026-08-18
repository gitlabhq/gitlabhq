import { GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import AlertStatus from '~/vue_shared/alert_details/components/alert_status.vue';
import AlertSidebarStatus from '~/vue_shared/alert_details/components/sidebar/sidebar_status.vue';
import { PAGE_CONFIG } from '~/vue_shared/alert_details/constants';
import mockAlerts from '../mocks/alerts.json';

Vue.use(VueApollo);

const mockAlert = mockAlerts[0];

describe('Alert Details Sidebar Status', () => {
  let wrapper;
  const findStatusLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlertStatus = () => wrapper.findComponent(AlertStatus);
  const findStatus = () => wrapper.findByTestId('status');

  function createComponent({ data, stubs = {}, provide = {} } = {}) {
    wrapper = shallowMountExtended(AlertSidebarStatus, {
      propsData: {
        alert: { ...mockAlert },
        ...data,
        projectPath: 'projectPath',
      },
      apolloProvider: createMockApollo(),
      stubs,
      provide,
    });
  }

  beforeEach(() => {
    createComponent({
      data: { alert: mockAlert },
    });
  });

  it('displays status dropdown', () => {
    expect(findAlertStatus().exists()).toBe(true);
  });

  describe('updating the alert status', () => {
    it('ensures dropdown is hidden when loading', async () => {
      createComponent({
        data: { alert: mockAlert },
      });
      findAlertStatus().vm.$emit('handle-updating', true);
      await nextTick();
      expect(findStatusLoadingIcon().exists()).toBe(true);
    });

    it('stops updating when the request fails', () => {
      createComponent({
        data: { alert: mockAlert },
      });
      findAlertStatus().vm.$emit('handle-updating', false);
      expect(findStatusLoadingIcon().exists()).toBe(false);
      expect(findStatus().text()).toBe('Triggered');
    });

    it('renders default translated statuses', () => {
      expect(findAlertStatus().props('statuses')).toBe(PAGE_CONFIG.OPERATIONS.STATUSES);
      expect(findStatus().text()).toBe('Triggered');
    });

    it('emits "alert-update" when the status has been updated', () => {
      expect(wrapper.emitted('alert-update')).toBeUndefined();
      findAlertStatus().vm.$emit('handle-updating');
      expect(wrapper.emitted('alert-update')).toEqual([[]]);
    });

    it('renders translated statuses', () => {
      const status = 'TEST';
      const statuses = { [status]: 'Test' };
      createComponent({
        data: { alert: { ...mockAlert, status } },
        provide: { statuses },
      });
      expect(findAlertStatus().props('statuses')).toBe(statuses);
      expect(findStatus().text()).toBe(statuses.TEST);
    });
  });
});
