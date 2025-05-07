import { shallowMount } from '@vue/test-utils';
import AdminRunnerShowApp from '~/ci/runner/admin_runner_show/admin_runner_show_app.vue';
import RunnerDetailsTabs from '~/ci/runner/components/runner_details_tabs.vue';

const mockRunnerId = '1';
const mockRunnersPath = '/runners';
const mockEditPath = '/runners/1/edit';

describe('AdminRunnerShowApp', () => {
  let wrapper;

  const findRunnerDetailsTabs = () => wrapper.findComponent(RunnerDetailsTabs);

  beforeEach(() => {
    wrapper = shallowMount(AdminRunnerShowApp, {
      propsData: {
        runnerId: mockRunnerId,
        runnersPath: mockRunnersPath,
        editPath: mockEditPath,
      },
    });
  });

  it('passes the correct props', () => {
    expect(findRunnerDetailsTabs().props()).toMatchObject({
      runnerId: mockRunnerId,
      runnersPath: mockRunnersPath,
      editPath: mockEditPath,
    });
  });
});
