import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import updateAlertStatusMutation from '~/graphql_shared//mutations/alert_status_update.mutation.graphql';
import Tracking from '~/tracking';
import AlertManagementStatus from '~/vue_shared/alert_details/components/alert_status.vue';
import mockAlerts from './mocks/alerts.json';

const mockAlert = mockAlerts[0];

describe('AlertManagementStatus', () => {
  let wrapper;
  const findStatusDropdown = () => wrapper.findComponent(GlDropdown);
  const findFirstStatusOption = () => findStatusDropdown().findComponent(GlDropdownItem);
  const findAllStatusOptions = () => findStatusDropdown().findAll(GlDropdownItem);
  const findStatusDropdownHeader = () => wrapper.findByTestId('dropdown-header');

  const selectFirstStatusOption = () => {
    findFirstStatusOption().vm.$emit('click');

    return waitForPromises();
  };

  function mountComponent({ props = {}, provide = {}, loading = false, stubs = {} } = {}) {
    wrapper = shallowMountExtended(AlertManagementStatus, {
      propsData: {
        alert: { ...mockAlert },
        projectPath: 'gitlab-org/gitlab',
        isSidebar: false,
        ...props,
      },
      provide,
      mocks: {
        $apollo: {
          mutate: jest.fn(),
          queries: {
            alert: {
              loading,
            },
          },
        },
      },
      stubs,
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('sidebar', () => {
    it('displays the dropdown status header', () => {
      mountComponent({ props: { isSidebar: true } });
      expect(findStatusDropdownHeader().exists()).toBe(true);
    });

    it('hides the dropdown by default', () => {
      mountComponent({ props: { isSidebar: true } });
      expect(wrapper.classes()).toContain('gl-display-none');
    });

    it('shows the dropdown', () => {
      mountComponent({ props: { isSidebar: true, isDropdownShowing: true } });
      expect(wrapper.classes()).toContain('show');
    });
  });

  describe('updating the alert status', () => {
    const iid = '1527542';
    const mockUpdatedMutationResult = {
      data: {
        updateAlertStatus: {
          errors: [],
          alert: {
            iid,
            status: 'acknowledged',
          },
        },
      },
    };

    beforeEach(() => {
      mountComponent({});
    });

    it('calls `$apollo.mutate` with `updateAlertStatus` mutation and variables containing `iid`, `status`, & `projectPath`', () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdatedMutationResult);
      findFirstStatusOption().vm.$emit('click');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: updateAlertStatusMutation,
        variables: {
          iid,
          status: 'TRIGGERED',
          projectPath: 'gitlab-org/gitlab',
        },
      });
    });

    describe('when a request fails', () => {
      beforeEach(() => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockReturnValue(Promise.reject(new Error()));
      });

      it('emits an error', async () => {
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
        await wrapper.vm.$nextTick();
        await selectFirstStatusOption();
        // Should emit two errors [0,1]
        expect(wrapper.emitted('alert-error').length > 1).toBe(true);
      });
    });

    it('shows an error when response includes HTML errors', async () => {
      const mockUpdatedMutationErrorResult = {
        data: {
          updateAlertStatus: {
            errors: ['<span data-testid="htmlError" />'],
            alert: {
              iid,
              status: 'acknowledged',
            },
          },
        },
      };

      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockUpdatedMutationErrorResult);

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
      expect(findAllStatusOptions().length).toBe(1);
      expect(findFirstStatusOption().text()).toBe(translatedStatus);
    });
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
    });

    it('should not track alert status updates when the tracking options do not exist', () => {
      mountComponent({});
      Tracking.event.mockClear();
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({});
      findFirstStatusOption().vm.$emit('click');
      setImmediate(() => {
        expect(Tracking.event).not.toHaveBeenCalled();
      });
    });

    it('should track alert status updates when the tracking options exist', () => {
      const trackAlertStatusUpdateOptions = {
        category: 'Alert Management',
        action: 'update_alert_status',
        label: 'Status',
      };
      mountComponent({ provide: { trackAlertStatusUpdateOptions } });
      Tracking.event.mockClear();
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue({});
      findFirstStatusOption().vm.$emit('click');
      const status = findFirstStatusOption().text();
      setImmediate(() => {
        const { category, action, label } = trackAlertStatusUpdateOptions;
        expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property: status });
      });
    });
  });
});
