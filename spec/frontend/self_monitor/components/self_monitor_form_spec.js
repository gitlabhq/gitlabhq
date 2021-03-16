import { GlButton, GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
import SelfMonitor from '~/self_monitor/components/self_monitor_form.vue';
import { createStore } from '~/self_monitor/store';

describe('self monitor component', () => {
  let wrapper;
  let store;

  describe('When the self monitor project has not been created', () => {
    beforeEach(() => {
      store = createStore({
        projectEnabled: false,
        selfMonitoringProjectExists: false,
        createSelfMonitoringProjectPath: '/create',
        deleteSelfMonitoringProjectPath: '/delete',
      });
    });

    afterEach(() => {
      if (wrapper.destroy) {
        wrapper.destroy();
      }
    });

    describe('default state', () => {
      it('to match the default snapshot', () => {
        wrapper = shallowMount(SelfMonitor, { store });

        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('renders header text', () => {
      wrapper = shallowMount(SelfMonitor, { store });

      expect(wrapper.find('.js-section-header').text()).toBe('Self monitoring');
    });

    describe('expand/collapse button', () => {
      it('renders as an expand button by default', () => {
        wrapper = shallowMount(SelfMonitor, { store });

        const button = wrapper.find(GlButton);

        expect(button.text()).toBe('Expand');
      });
    });

    describe('sub-header', () => {
      it('renders descriptive text', () => {
        wrapper = shallowMount(SelfMonitor, { store });

        expect(wrapper.find('.js-section-sub-header').text()).toContain(
          'Enable or disable instance self monitoring',
        );
      });
    });

    describe('settings-content', () => {
      it('renders the form description without a link', () => {
        wrapper = shallowMount(SelfMonitor, { store });

        expect(wrapper.vm.selfMonitoringFormText).toContain(
          'Enabling this feature creates a project that can be used to monitor the health of your instance.',
        );
      });

      it('renders the form description with a link', () => {
        store = createStore({
          projectEnabled: true,
          selfMonitoringProjectExists: true,
          createSelfMonitoringProjectPath: '/create',
          deleteSelfMonitoringProjectPath: '/delete',
          selfMonitoringProjectFullPath: 'instance-administrators-random/gitlab-self-monitoring',
        });

        wrapper = shallowMount(SelfMonitor, { store });

        expect(
          wrapper.find({ ref: 'selfMonitoringFormText' }).find('a').attributes('href'),
        ).toEqual(`${TEST_HOST}/instance-administrators-random/gitlab-self-monitoring`);
      });

      it('renders toggle', () => {
        wrapper = shallowMount(SelfMonitor, { store });

        expect(wrapper.findComponent(GlToggle).props('label')).toBe(
          SelfMonitor.formLabels.createProject,
        );
      });
    });
  });
});
