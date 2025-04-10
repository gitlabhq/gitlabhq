import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlankProjectForm from '~/projects/new_v2/components/blank_project_form.vue';
import SharedProjectCreationFields from '~/projects/new_v2/components/shared_project_creation_fields.vue';

describe('Blank Project Form', () => {
  let wrapper;

  const defaultProps = {
    option: {
      title: 'Import project',
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BlankProjectForm, {
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
  const findSharedProjectCreationFields = () => wrapper.findComponent(SharedProjectCreationFields);
  const findCreateButton = () => wrapper.findByTestId('create-project-button');
  const findBackButton = () => wrapper.findByTestId('create-project-back-button');

  it('passes the correct props to MultiStepFormTemplate', () => {
    expect(findMultiStepFormTemplate().props()).toMatchObject({
      title: defaultProps.option.title,
      currentStep: 2,
      stepsTotal: 2,
    });
  });

  describe('form', () => {
    it('renders the SharedProjectCreationFields component', () => {
      expect(findSharedProjectCreationFields().exists()).toBe(true);
    });
  });

  it('renders the option to Create Project as disabled', () => {
    expect(findCreateButton().text()).toBe('Create project');
    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it(`emits the "back" event when the back button is clicked`, () => {
    findBackButton().vm.$emit('click');
    expect(wrapper.emitted('back')).toHaveLength(1);
  });
});
