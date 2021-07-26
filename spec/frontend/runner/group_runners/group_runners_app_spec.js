import { shallowMount } from '@vue/test-utils';
import RunnerTypeHelp from '~/runner/components/runner_type_help.vue';
import GroupRunnersApp from '~/runner/group_runners/group_runners_app.vue';

describe('GroupRunnersApp', () => {
  let wrapper;

  const findRunnerTypeHelp = () => wrapper.findComponent(RunnerTypeHelp);

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(GroupRunnersApp);
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows the runner type help', () => {
    expect(findRunnerTypeHelp().exists()).toBe(true);
  });
});
