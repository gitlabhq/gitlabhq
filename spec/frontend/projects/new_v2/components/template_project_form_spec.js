import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TemplateProjectForm from '~/projects/new_v2/components/template_project_form.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

describe('Template Project Form', () => {
  let wrapper;

  const defaultProps = {
    option: {
      title: 'Template project',
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TemplateProjectForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findMultiStepFormTemplate = () => wrapper.findComponent(MultiStepFormTemplate);
  const findNextButton = () => wrapper.findByTestId('template-project-next-button');
  const findBackButton = () => wrapper.findByTestId('template-project-back-button');

  beforeEach(() => {
    createComponent();
  });

  it('passes the correct props to MultiStepFormTemplate', () => {
    expect(findMultiStepFormTemplate().props()).toMatchObject({
      title: defaultProps.option.title,
      currentStep: 2,
      stepsTotal: 3,
    });
  });

  it('renders the option to move to Next Step', () => {
    expect(findNextButton().text()).toBe('Next step');
  });

  it(`emits the "back" event when the back button is clicked`, () => {
    findBackButton().vm.$emit('click');
    expect(wrapper.emitted('back')).toHaveLength(1);
  });
});
