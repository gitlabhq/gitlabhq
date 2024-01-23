import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCloudConnectionForm from '~/ci/runner/components/runner_cloud_connection_form.vue';

describe('Runner Cloud Form', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(RunnerCloudConnectionForm);
  };

  it('default', () => {
    createComponent();

    expect(wrapper.exists()).toBe(true);
  });
});
