import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CICDProjectForm from '~/projects/new_v2/components/ci_cd_project_form.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

describe('CI/CD Project Form', () => {
  let wrapper;

  const defaultProps = {
    option: {
      title: 'Import project',
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(CICDProjectForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findMultiStepFormTemplate = () => wrapper.findComponent(MultiStepFormTemplate);
  const findCreateButton = () => wrapper.findByTestId('create-cicd-project-button');
  const findBackButton = () => wrapper.findByTestId('create-cicd-project-back-button');

  it('passes the correct props to MultiStepFormTemplate', () => {
    expect(findMultiStepFormTemplate().props()).toMatchObject({
      title: defaultProps.option.title,
      currentStep: 2,
      stepsTotal: 2,
    });
  });

  it('renders the option to Create Project', () => {
    expect(findCreateButton().text()).toBe('Create project');
  });

  it(`emits the "back" event when the back button is clicked`, () => {
    findBackButton().vm.$emit('click');
    expect(wrapper.emitted('back')).toHaveLength(1);
  });
});
