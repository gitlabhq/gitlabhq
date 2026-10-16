import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCreateWizard from '~/ci/runner/components/runner_create_wizard.vue';
import RunnerCreateWizardRequiredFields from '~/ci/runner/components/runner_create_wizard_required_fields.vue';
import { INSTANCE_TYPE } from '~/ci/runner/constants';

describe('Create Runner Wizard', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(RunnerCreateWizard, {
      propsData: {
        runnerType: INSTANCE_TYPE,
        runnersPath: '/admin/runners',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findRequiredFieldsComponent = () => wrapper.findComponent(RunnerCreateWizardRequiredFields);

  it('renders step 1 form', () => {
    expect(findRequiredFieldsComponent().exists()).toBe(true);
  });
});
