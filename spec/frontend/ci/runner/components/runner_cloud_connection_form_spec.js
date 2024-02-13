import { GlAccordion, GlLink } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCloudConnectionForm from '~/ci/runner/components/runner_cloud_connection_form.vue';

describe('Runner Cloud Connection Form', () => {
  let wrapper;

  const findContinueBtn = () => wrapper.findByTestId('continue-btn');
  const findProjectIdInput = () => wrapper.findByTestId('project-id-input');
  const findDocsLink = () => wrapper.findComponent(GlLink);
  const findConfigurationInstructions = () => wrapper.findComponent(GlAccordion);

  const createComponent = (mountFn = shallowMountExtended) => {
    wrapper = mountFn(RunnerCloudConnectionForm);
  };

  it('displays all inputs', () => {
    createComponent();

    expect(findProjectIdInput().exists()).toBe(true);
  });

  it('contains external docs link', () => {
    createComponent(mountExtended);

    expect(findDocsLink().attributes('href')).toBe(
      'https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects',
    );
  });

  it('emits project id', () => {
    createComponent(mountExtended);

    const projectId = '12';

    findProjectIdInput().vm.$emit('input', projectId);

    findContinueBtn().vm.$emit('click');

    expect(wrapper.emitted()).toMatchObject({ continue: [[projectId]] });
  });

  it('displays configuration instructions', () => {
    createComponent();

    expect(findConfigurationInstructions().exists()).toBe(true);
  });
});
