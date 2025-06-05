import { shallowMount } from '@vue/test-utils';
import ProjectRunnerShowApp from '~/ci/runner/project_runner_show/project_runner_show_app.vue';
import RunnerShow from '~/ci/runner/components/runner_show.vue';

const mockRunnerId = '1';
const mockRunnersPath = '/runners';
const mockEditPath = '/runners/1/edit';

describe('ProjectRunnerShowApp', () => {
  let wrapper;

  const findRunnerShow = () => wrapper.findComponent(RunnerShow);

  beforeEach(() => {
    wrapper = shallowMount(ProjectRunnerShowApp, {
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
