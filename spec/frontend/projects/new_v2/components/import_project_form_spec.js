import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ImportProjectForm from '~/projects/new_v2/components/import_project_form.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

describe('Import Project Form', () => {
  let wrapper;

  const defaultProps = {
    option: {
      title: 'Import project',
      namespaceId: '',
    },
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(ImportProjectForm, {
      propsData: {
        ...defaultProps,
      },
      provide: {
        importGitlabEnabled: true,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findMultiStepFormTemplate = () => wrapper.findComponent(MultiStepFormTemplate);
  const findNextButton = () => wrapper.findByTestId('import-project-next-button');
  const findBackButton = () => wrapper.findByTestId('import-project-back-button');

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
