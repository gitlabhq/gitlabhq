import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import OfflineTransferExportApp from '~/import/offline_transfer/export/app.vue';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import SelectGroupsTab from '~/import/offline_transfer/components/select_groups_tab.vue';
import offlineTransferSourceOwnedGroupsQuery from '~/import/offline_transfer/graphql/queries/offline_transfer_source_owned_groups.query.graphql';
import { OFFLINE_EXPORT_STEPS } from '~/import/offline_transfer/constants';
import { mockGroups, mockGroupsResponse } from '../mock_data';

Vue.use(VueApollo);

describe('OfflineTransferExportApp', () => {
  let wrapper;

  const defaultHandler = jest.fn().mockResolvedValue(mockGroupsResponse);

  const createComponent = ({ handler = defaultHandler } = {}) => {
    const apolloProvider = createMockApollo([[offlineTransferSourceOwnedGroupsQuery, handler]]);

    wrapper = shallowMountExtended(OfflineTransferExportApp, { apolloProvider });
  };

  const findFormStepper = () => wrapper.findComponent(FormStepper);
  const findSelectGroupsTab = () => wrapper.findComponent(SelectGroupsTab);
  const findCompletionAlert = () => wrapper.findByTestId('completion-alert');
  const findValidationErrorAlert = () => wrapper.findByTestId('validation-alert');
  const findFetchErrorAlert = () => wrapper.findByTestId('fetch-error-alert');

  describe('passes to FormStepper', () => {
    beforeEach(() => {
      createComponent();
    });

    it('the correct steps', () => {
      expect(findFormStepper().props('steps')).toBe(OFFLINE_EXPORT_STEPS);
    });

    it('the correct completion button text', () => {
      expect(findFormStepper().props('completionButtonText')).toBe('Start export');
    });

    it('validateStep as a function', () => {
      expect(findFormStepper().props('validateStep')).toBeInstanceOf(Function);
    });
  });

  describe('events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('triggers a completion alert when FormStepper emits complete', async () => {
      expect(findCompletionAlert().exists()).toBe(false);

      await findFormStepper().vm.$emit('complete');

      expect(findCompletionAlert().exists()).toBe(true);
    });

    it('triggers a validation error alert when FormStepper emits validation-failed', async () => {
      expect(findValidationErrorAlert().exists()).toBe(false);

      await findFormStepper().vm.$emit('validation-failed');

      expect(findValidationErrorAlert().exists()).toBe(true);
    });

    it('sets the previously completed step as invalid after FormStepper emits stepped-back', async () => {
      wrapper.vm.isStepComplete.configure = true;
      expect(findFormStepper().props('validateStep')(1)).toBe(true);

      await findFormStepper().vm.$emit('stepped-back', {
        previousTabIndex: 1,
      });

      expect(findFormStepper().props('validateStep')(1)).toBe(false);
    });
  });

  describe('Select Groups tab', () => {
    it('receives groups returned by the query', async () => {
      createComponent();
      await waitForPromises();

      expect(
        findSelectGroupsTab()
          .props('groups')
          .map((group) => group.id),
      ).toEqual(['gid://glab/Group/1', 'gid://glab/Group/2', 'gid://glab/Group/3']);
    });

    it('receives query loading state', async () => {
      createComponent();

      expect(findSelectGroupsTab().props('loading')).toBe(true);

      await waitForPromises();

      expect(findSelectGroupsTab().props('loading')).toBe(false);
    });

    it('shows the fetch error alert when groups query fails', async () => {
      createComponent({ handler: jest.fn().mockRejectedValue(new Error('query failed')) });
      await waitForPromises();

      expect(findFetchErrorAlert().exists()).toBe(true);
    });

    describe('selection', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('when emits `toggle`, adds a group to the selected collection', async () => {
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([mockGroups[0].id]);
      });

      it('when toggled again, removes group from the selection', async () => {
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([]);
      });

      it('when emits `select-all` adds every group', async () => {
        findSelectGroupsTab().vm.$emit('select-all');
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([
          'gid://glab/Group/1',
          'gid://glab/Group/2',
          'gid://glab/Group/3',
        ]);
      });

      it('when emits `deselect-all` empties the collection', async () => {
        findSelectGroupsTab().vm.$emit('select-all');
        await nextTick();
        findSelectGroupsTab().vm.$emit('deselect-all');
        await nextTick();

        expect(findSelectGroupsTab().props('selectedIds')).toEqual([]);
      });
    });

    describe('step validation', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('keeps Select Group step invalid while nothing is selected', () => {
        expect(findFormStepper().props('validateStep')(0)).toBe(false);
      });

      it('makes Select Group step valid once a group is selected', async () => {
        findSelectGroupsTab().vm.$emit('toggle', mockGroups[0]);
        await nextTick();

        expect(findFormStepper().props('validateStep')(0)).toBe(true);
      });
    });
  });
});
