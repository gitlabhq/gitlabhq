import { shallowMount } from '@vue/test-utils';
import GroupRunnerShowApp from '~/ci/runner/group_runner_show/group_runner_show_app.vue';
import RunnerShow from '~/ci/runner/components/runner_show.vue';

const mockRunnerId = '1';
const mockRunnersPath = '/runners';
const mockEditPath = '/runners/1/edit';

describe('GroupRunnerShowApp', () => {
  let wrapper;

  const findRunnerShow = () => wrapper.findComponent(RunnerShow);

  beforeEach(() => {
    wrapper = shallowMount(GroupRunnerShowApp, {
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
        editPath: mockEditPath,
      },
    });
  });

  it('passes the correct props', () => {
    expect(findRunnerShow().props()).toEqual({
      runnerId: mockRunnerId,
      runnersPath: mockRunnersPath,
      editPath: mockEditPath,
      showAccessHelp: true,
    });
  });
});
