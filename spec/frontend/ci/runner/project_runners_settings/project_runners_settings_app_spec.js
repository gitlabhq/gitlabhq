import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlAlert } from '@gitlab/ui';

import * as Sentry from '~/sentry/sentry_browser_wrapper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import RegistrationDropdown from '~/ci/runner/components/registration/registration_dropdown.vue';
import RunnersTabs from '~/ci/runner/project_runners_settings/components/runners_tabs.vue';

import ProjectRunnersSettingsApp from '~/ci/runner/project_runners_settings/project_runners_settings_app.vue';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('ProjectRunnersSettingsApp', () => {
  let wrapper;

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(ProjectRunnersSettingsApp, {
      propsData: {
        canCreateRunner: true,
        allowRegistrationToken: true,
        registrationToken: 'token123',
        newProjectRunnerPath: '/runners/new',
        projectFullPath: 'group/project',
        ...props,
      },
      stubs: {
        CrudComponent,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findNewRunnerButton = () => wrapper.findComponent(GlButton);
  const findRegistrationDropdown = () => wrapper.findComponent(RegistrationDropdown);
  const findRunnersTabs = () => wrapper.findComponent(RunnersTabs);

  beforeEach(() => {
    createComponent();
  });

  it('renders the crud component with correct title', () => {
    expect(findCrudComponent().props('title')).toBe('Available Runners');
  });

  it('renders new runner button when canCreateRunner is true', () => {
    expect(findNewRunnerButton().attributes('href')).toBe('/runners/new');
    expect(findNewRunnerButton().text()).toBe('New project runner');
  });

  it('does not render new runner button when canCreateRunner is false', () => {
    createComponent({
      props: { canCreateRunner: false },
    });

    expect(findNewRunnerButton().exists()).toBe(false);
  });

  it('renders registration dropdown with correct props', () => {
    expect(findRegistrationDropdown().props()).toMatchObject({
      type: 'PROJECT_TYPE',
      allowRegistrationToken: true,
      registrationToken: 'token123',
    });
  });

  it('renders runners tabs with correct props', () => {
    expect(findRunnersTabs().props('projectFullPath')).toBe('group/project');
  });

  it('does not show error alert by default', () => {
    expect(findAlert().exists()).toBe(false);
  });

  describe('when an error occurs', () => {
    const error = new Error('Test error');

    beforeEach(async () => {
      findRunnersTabs().vm.$emit('error', error);

      await nextTick();
    });

    it('shows error alert', () => {
      expect(findAlert().text()).toBe('Something went wrong while fetching runner data.');
      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });

    it('dismisses error alert', async () => {
      expect(findAlert().exists()).toBe(true);

      findAlert().vm.$emit('dismiss');
      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });
  });
});
