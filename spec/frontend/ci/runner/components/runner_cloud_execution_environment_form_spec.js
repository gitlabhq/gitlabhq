import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCloudExecutionEnvironment from '~/ci/runner/components/runner_cloud_execution_environment.vue';
import RunnerCreateFormNew from '~/ci/runner/components/runner_create_form_new.vue';
import { PROJECT_TYPE } from '~/ci/runner/constants';

describe('Runner Cloud Execution Environment Form', () => {
  let wrapper;

  const findRegionDropdown = () => wrapper.findByTestId('region-dropdown');
  const findZoneDropdown = () => wrapper.findByTestId('zone-dropdown');
  const findMachineTypeDropdown = () => wrapper.findByTestId('machine-type-dropdown');
  const findRunnerCreateFormNew = () => wrapper.findComponent(RunnerCreateFormNew);

  const defaultProps = {
    projectId: '23',
    runnerType: PROJECT_TYPE,
  };

  const createComponent = (mountFn = shallowMountExtended) => {
    wrapper = mountFn(RunnerCloudExecutionEnvironment, {
      propsData: {
        ...defaultProps,
      },
    });
  };

  it('displays the region, zone and machine type dropdowns', () => {
    createComponent();

    expect(findRegionDropdown().exists()).toBe(true);
    expect(findZoneDropdown().exists()).toBe(true);
    expect(findMachineTypeDropdown().exists()).toBe(true);
  });

  it('should display the runner create form for added details', () => {
    createComponent();

    expect(findRunnerCreateFormNew().exists()).toBe(true);
  });
});
