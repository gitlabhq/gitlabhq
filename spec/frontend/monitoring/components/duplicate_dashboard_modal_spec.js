import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlLoadingIcon, GlModal } from '@gitlab/ui';

import waitForPromises from 'helpers/wait_for_promises';

import DuplicateDashboardModal from '~/monitoring/components/duplicate_dashboard_modal.vue';
import DuplicateDashboardForm from '~/monitoring/components/duplicate_dashboard_form.vue';

import { dashboardGitResponse } from '../mock_data';

describe('duplicate dashboard modal', () => {
  let wrapper;
  let mockDashboards;
  let mockSelectedDashboard;
  let duplicateDashboardAction;
  let okEvent;

  function createComponent(opts = {}) {
    const storeOpts = {
      methods: {
        duplicateSystemDashboard: jest.fn(),
      },
      computed: {
        allDashboards: () => mockDashboards,
        selectedDashboard: () => mockSelectedDashboard,
      },
    };

    return shallowMount(DuplicateDashboardModal, {
      propsData: {
        defaultBranch: 'master',
        modalId: 'id',
      },
      sync: false,
      ...storeOpts,
      ...opts,
    });
  }

  const findAlert = () => wrapper.find(GlAlert);
  const findModal = () => wrapper.find(GlModal);
  const findDuplicateDashboardForm = () => wrapper.find(DuplicateDashboardForm);

  beforeEach(() => {
    mockDashboards = dashboardGitResponse;
    [mockSelectedDashboard] = dashboardGitResponse;

    duplicateDashboardAction = jest.fn().mockResolvedValue();

    okEvent = {
      preventDefault: jest.fn(),
    };

    wrapper = createComponent({
      methods: {
        // Mock vuex actions
        duplicateSystemDashboard: duplicateDashboardAction,
      },
    });

    wrapper.vm.$refs.duplicateDashboardModal.hide = jest.fn();
  });

  it('contains a form to duplicate a dashboard', () => {
    expect(findDuplicateDashboardForm().exists()).toBe(true);
  });

  it('saves a new dashboard', () => {
    findModal().vm.$emit('ok', okEvent);

    return waitForPromises().then(() => {
      expect(okEvent.preventDefault).toHaveBeenCalled();
      expect(wrapper.emitted().dashboardDuplicated).toBeTruthy();
      expect(wrapper.emitted().dashboardDuplicated[0]).toEqual([dashboardGitResponse[0]]);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.vm.$refs.duplicateDashboardModal.hide).toHaveBeenCalled();
      expect(findAlert().exists()).toBe(false);
    });
  });

  it('handles error when a new dashboard is not saved', () => {
    const errMsg = 'An error occurred';

    duplicateDashboardAction.mockRejectedValueOnce(errMsg);
    findModal().vm.$emit('ok', okEvent);

    return waitForPromises().then(() => {
      expect(okEvent.preventDefault).toHaveBeenCalled();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(errMsg);

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.vm.$refs.duplicateDashboardModal.hide).not.toHaveBeenCalled();
    });
  });

  it('updates the form on changes', () => {
    const formVals = {
      dashboard: 'common_metrics.yml',
      commitMessage: 'A commit message',
    };

    findModal()
      .find(DuplicateDashboardForm)
      .vm.$emit('change', formVals);

    // Binding's second argument contains the modal id
    expect(wrapper.vm.form).toEqual(formVals);
  });
});
