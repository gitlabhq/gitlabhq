import { nextTick } from 'vue';
import { GlFormInput, GlAlert, GlButton } from '@gitlab/ui';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerCreateWizardRequiredFields from '~/ci/runner/components/runner_create_wizard_required_fields.vue';

describe('Create Runner Required Fields', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(RunnerCreateWizardRequiredFields, {
      propsData: {
        currentStep: 1,
        stepsTotal: 3,
        isRunUntagged: false,
        tagList: '',
      },
      stubs: {
        GlFormInput,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findMultiStepFormTemplate = () => wrapper.findComponent(MultiStepFormTemplate);
  const findNextButton = () => wrapper.findComponent(GlButton);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTagsInput = () => wrapper.findByTestId('runner-tags-input');
  const findRunUntaggedCheckbox = () => wrapper.findByTestId('runner-untagged-checkbox');

  describe('form', () => {
    it('passes the correct props to MultiStepFormTemplate', () => {
      expect(findMultiStepFormTemplate().props()).toMatchObject({
        title: 'Create instance runner',
        currentStep: 1,
        stepsTotal: 3,
      });
    });

    it('renders error when user click next button with no tags or runUntagged provided', async () => {
      findNextButton().vm.$emit('click');
      await nextTick();

      expect(findAlert().exists()).toBe(true);
    });

    it('does not render error when user click next button with tags provided', async () => {
      findTagsInput().setValue('tag1, tag2');
      findTagsInput().trigger('blur');
      findNextButton().vm.$emit('click');
      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });

    it('does not renders error when user click next button with runUntagged provided', async () => {
      findRunUntaggedCheckbox().vm.$emit('input', ['untagged']);
      findNextButton().vm.$emit('click');
      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });
  });

  it('renders the Next step button', () => {
    expect(findNextButton().text()).toBe('Next step');
  });
});
