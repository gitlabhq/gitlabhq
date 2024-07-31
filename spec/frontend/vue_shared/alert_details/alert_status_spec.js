import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import updateAlertStatusMutation from '~/graphql_shared//mutations/alert_status_update.mutation.graphql';
import Tracking from '~/tracking';
import AlertManagementStatus from '~/vue_shared/alert_details/components/alert_status.vue';
import mockAlerts from './mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('AlertManagementStatus', () => {
  let wrapper;
  let requestHandler;

  const iid = '1527542';
  const mockUpdatedMutationResult = ({ errors = [], nodes = [] } = {}) =>
    jest.fn().mockResolvedValue({
      data: {
        updateAlertStatus: {
          errors,
          alert: {
            id: '1',
            iid,
            status: 'acknowledged',
            endedAt: 'endedAt',
            notes: {
              nodes,
            },
          },
        },
      },
    });

  const findStatusDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findFirstStatusOption = () => findStatusDropdown().findComponent(GlListboxItem);
  const findAllStatusOptions = () => findStatusDropdown().findAllComponents(GlListboxItem);
  const findStatusDropdownHeader = () => wrapper.findByTestId('listbox-header-text');

  const selectFirstStatusOption = () => {
    findFirstStatusOption().vm.$emit('select', new Event('click'));

    return waitForPromises();
  };

  const createMockApolloProvider = (handler) => {
    Vue.use(VueApollo);
    requestHandler = handler;

    return createMockApollo([[updateAlertStatusMutation, handler]]);
  };

  function mountComponent({
    props = {},
    provide = {},
    handler = mockUpdatedMutationResult(),
  } = {}) {
    wrapper = mountExtended(AlertManagementStatus, {
      apolloProvider: createMockApolloProvider(handler),
      propsData: {
        alert: { ...mockAlert },
        projectPath: 'gitlab-org/gitlab',
        isSidebar: false,
        ...props,
      },
      provide,
    });
  }

  describe('sidebar', () => {
    it('displays the dropdown status header', () => {
      mountComponent({ props: { isSidebar: true } });
      expect(findStatusDropdownHeader().exists()).toBe(true);
    });

    it('hides the dropdown by default', () => {
      mountComponent({ props: { isSidebar: true } });
      expect(wrapper.classes()).toContain('gl-hidden');
    });

    it('shows the dropdown', () => {
      mountComponent({ props: { isSidebar: true, isDropdownShowing: true } });
      expect(wrapper.classes()).not.toContain('gl-hidden');
    });
  });

  describe('updating the alert status', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('calls `$apollo.mutate` with `updateAlertStatus` mutation and variables containing `iid`, `status`, & `projectPath`', async () => {
      await selectFirstStatusOption();

      expect(requestHandler).toHaveBeenCalledWith({
        iid,
        status: 'TRIGGERED',
        projectPath: 'gitlab-org/gitlab',
      });
    });

    describe('when a request fails', () => {
      beforeEach(async () => {
        mountComponent({
          handler: mockUpdatedMutationResult({ errors: ['<span data-testid="htmlError" />'] }),
        });
        await waitForPromises();
      });

      it('emits an error', async () => {
        mountComponent({ handler: jest.fn().mockRejectedValue({}) });
        await waitForPromises();
        await selectFirstStatusOption();

        expect(wrapper.emitted('alert-error')[0]).toEqual([
          'There was an error while updating the status of the alert. Please try again.',
        ]);
      });

      it('emits an update event at the start and ending of the updating', async () => {
        await selectFirstStatusOption();
        expect(wrapper.emitted('handle-updating').length > 1).toBe(true);
        expect(wrapper.emitted('handle-updating')[0]).toEqual([true]);
        expect(wrapper.emitted('handle-updating')[1]).toEqual([false]);
      });

      it('emits an error when triggered a second time', async () => {
        await selectFirstStatusOption();
        await selectFirstStatusOption();
        // Should emit two errors [0,1]
        expect(wrapper.emitted('alert-error').length > 1).toBe(true);
      });
    });

    it('shows an error when response includes HTML errors', async () => {
      mountComponent({
        handler: mockUpdatedMutationResult({ errors: ['<span data-testid="htmlError" />'] }),
      });

      await selectFirstStatusOption();

      expect(wrapper.emitted('alert-error').length > 0).toBe(true);
      expect(wrapper.emitted('alert-error')[0]).toEqual([
        'There was an error while updating the status of the alert. <span data-testid="htmlError" />',
      ]);
    });
  });

  describe('Statuses', () => {
    it('renders default translated statuses', () => {
      mountComponent({});
      expect(findAllStatusOptions().length).toBe(3);
      expect(findFirstStatusOption().text()).toBe('Triggered');
    });

    it('renders translated statuses', () => {
      const status = 'TEST';
      const translatedStatus = 'Test';
      mountComponent({
        props: { alert: { ...mockAlert, status }, statuses: { [status]: translatedStatus } },
      });
      expect(findAllStatusOptions()).toHaveLength(1);
      expect(findFirstStatusOption().text()).toBe(translatedStatus);
    });
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
    });

    it('should not track alert status updates when the tracking options do not exist', async () => {
      mountComponent({});
      Tracking.event.mockClear();

      findFirstStatusOption().vm.$emit('click');

      await waitForPromises();

      expect(Tracking.event).not.toHaveBeenCalled();
    });

    it('should track alert status updates when the tracking options exist', async () => {
      const trackAlertStatusUpdateOptions = {
        category: 'Alert Management',
        action: 'update_alert_status',
        label: 'Status',
      };
      mountComponent({
        provide: { trackAlertStatusUpdateOptions },
        handler: mockUpdatedMutationResult({ nodes: mockAlerts }),
      });
      Tracking.event.mockClear();
      await selectFirstStatusOption();

      const status = findFirstStatusOption().text();
      const { category, action, label } = trackAlertStatusUpdateOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property: status });
    });
  });
});
