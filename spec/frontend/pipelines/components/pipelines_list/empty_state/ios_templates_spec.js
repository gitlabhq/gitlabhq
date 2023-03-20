import '~/commons';
import { nextTick } from 'vue';
import { GlPopover, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import IosTemplates from '~/pipelines/components/pipelines_list/empty_state/ios_templates.vue';
import CiTemplates from '~/pipelines/components/pipelines_list/empty_state/ci_templates.vue';

const pipelineEditorPath = '/-/ci/editor';
const registrationToken = 'SECRET_TOKEN';
const iOSTemplateName = 'iOS-Fastlane';

describe('iOS Templates', () => {
  let wrapper;

  const createWrapper = (providedPropsData = {}) => {
    return shallowMountExtended(IosTemplates, {
      provide: {
        pipelineEditorPath,
        iosRunnersAvailable: true,
        ...providedPropsData,
      },
      propsData: {
        registrationToken,
      },
      stubs: {
        GlButton,
      },
    });
  };

  const findIosTemplate = () => wrapper.findComponent(CiTemplates);
  const findRunnerInstructionsModal = () => wrapper.findComponent(RunnerInstructionsModal);
  const findRunnerInstructionsPopover = () => wrapper.findComponent(GlPopover);
  const findRunnerSetupTodoEmoji = () => wrapper.findByTestId('runner-setup-marked-todo');
  const findRunnerSetupCompletedEmoji = () => wrapper.findByTestId('runner-setup-marked-completed');
  const findSetupRunnerLink = () => wrapper.findByText('Set up a runner');
  const configurePipelineLink = () => wrapper.findByTestId('configure-pipeline-link');

  describe('when ios runners are not available', () => {
    beforeEach(() => {
      wrapper = createWrapper({ iosRunnersAvailable: false });
    });

    describe('the runner setup section', () => {
      it('marks the section as todo', () => {
        expect(findRunnerSetupTodoEmoji().isVisible()).toBe(true);
        expect(findRunnerSetupCompletedEmoji().isVisible()).toBe(false);
      });

      it('renders the setup runner link', () => {
        expect(findSetupRunnerLink().exists()).toBe(true);
      });

      it('renders the runner instructions modal with a popover once clicked', async () => {
        findSetupRunnerLink().element.parentElement.click();

        await nextTick();

        expect(findRunnerInstructionsModal().exists()).toBe(true);
        expect(findRunnerInstructionsModal().props('registrationToken')).toBe(registrationToken);
        expect(findRunnerInstructionsModal().props('defaultPlatformName')).toBe('osx');

        findRunnerInstructionsModal().vm.$emit('shown');

        await nextTick();

        expect(findRunnerInstructionsPopover().exists()).toBe(true);
      });
    });

    describe('the configure pipeline section', () => {
      it('has a disabled link button', () => {
        expect(configurePipelineLink().props('disabled')).toBe(true);
      });
    });

    describe('the ios-Fastlane template', () => {
      it('renders the template', () => {
        expect(findIosTemplate().props('filterTemplates')).toStrictEqual([iOSTemplateName]);
      });

      it('has a disabled link button', () => {
        expect(findIosTemplate().props('disabled')).toBe(true);
      });
    });
  });

  describe('when ios runners are available', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    describe('the runner setup section', () => {
      it('marks the section as completed', () => {
        expect(findRunnerSetupTodoEmoji().isVisible()).toBe(false);
        expect(findRunnerSetupCompletedEmoji().isVisible()).toBe(true);
      });

      it('does not render the setup runner link', () => {
        expect(findSetupRunnerLink().exists()).toBe(false);
      });
    });

    describe('the configure pipeline section', () => {
      it('has an enabled link button', () => {
        expect(configurePipelineLink().props('disabled')).toBe(false);
      });

      it('links to the pipeline editor with the right template', () => {
        expect(configurePipelineLink().attributes('href')).toBe(
          `${pipelineEditorPath}?template=${iOSTemplateName}`,
        );
      });
    });

    describe('the ios-Fastlane template', () => {
      it('renders the template', () => {
        expect(findIosTemplate().props('filterTemplates')).toStrictEqual([iOSTemplateName]);
      });

      it('has an enabled link button', () => {
        expect(findIosTemplate().props('disabled')).toBe(false);
      });

      it('links to the pipeline editor with the right template', () => {
        expect(configurePipelineLink().attributes('href')).toBe(
          `${pipelineEditorPath}?template=${iOSTemplateName}`,
        );
      });
    });
  });
});
