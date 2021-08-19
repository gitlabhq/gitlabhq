import { shallowMount } from '@vue/test-utils';
import RunnerManualSetupHelp from '~/runner/components/runner_manual_setup_help.vue';
import RunnerTypeHelp from '~/runner/components/runner_type_help.vue';
import GroupRunnersApp from '~/runner/group_runners/group_runners_app.vue';

const mockRegistrationToken = 'AABBCC';

describe('GroupRunnersApp', () => {
  let wrapper;

  const findRunnerTypeHelp = () => wrapper.findComponent(RunnerTypeHelp);
  const findRunnerManualSetupHelp = () => wrapper.findComponent(RunnerManualSetupHelp);

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(GroupRunnersApp, {
      propsData: {
        registrationToken: mockRegistrationToken,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows the runner type help', () => {
    expect(findRunnerTypeHelp().exists()).toBe(true);
  });

  it('shows the runner setup instructions', () => {
    expect(findRunnerManualSetupHelp().exists()).toBe(true);
    expect(findRunnerManualSetupHelp().props('registrationToken')).toBe(mockRegistrationToken);
  });
});
