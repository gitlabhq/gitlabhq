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
    namespace: {
      id: '1',
      fullPath: 'root',
      isPersonal: true,
    },
  };

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = shallowMountExtended(BlankProjectForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...provide,
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

  describe('configuraqtion block', () => {
    it('renders the block', () => {
      expect(wrapper.findByTestId('configuration-form-group').exists()).toBe(true);
    });

    it('does not render SHA-256 option by default', () => {
      expect(wrapper.findByTestId('initialize-with-sha-256-checkbox').exists()).toBe(false);
    });

    it('renders SHA-256 option when it is available', () => {
      createComponent({ provide: { displaySha256Repository: true } });
      expect(wrapper.findByTestId('initialize-with-sha-256-checkbox').exists()).toBe(true);
    });

    it('check readme option by default', () => {
      expect(wrapper.findByTestId('configuration-selector').attributes('checked')).toBe('readme');
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
