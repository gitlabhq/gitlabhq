import { Document, parseDocument } from 'yaml';
import { GlProgressBar } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineWizardWrapper, { i18n } from '~/pipeline_wizard/components/wrapper.vue';
import WizardStep from '~/pipeline_wizard/components/step.vue';
import CommitStep from '~/pipeline_wizard/components/commit.vue';
import YamlEditor from '~/pipeline_wizard/components/editor.vue';
import { sprintf } from '~/locale';
import { steps as stepsYaml } from '../mock/yaml';

describe('Pipeline Wizard - wrapper.vue', () => {
  let wrapper;
  const steps = parseDocument(stepsYaml).toJS();

  const getAsYamlNode = (value) => new Document(value).contents;
  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PipelineWizardWrapper, {
      propsData: {
        projectPath: '/user/repo',
        defaultBranch: 'main',
        filename: '.gitlab-ci.yml',
        steps: getAsYamlNode(steps),
        ...props,
      },
    });
  };
  const getEditorContent = () => {
    return wrapper.getComponent(YamlEditor).attributes().doc.toString();
  };
  const getStepWrapper = () => wrapper.getComponent(WizardStep);
  const getGlProgressBarWrapper = () => wrapper.getComponent(GlProgressBar);

  describe('display', () => {
    afterEach(() => {
      wrapper.destroy();
    });

    it('shows the steps', () => {
      createComponent();

      expect(getStepWrapper().exists()).toBe(true);
    });

    it('shows the progress bar', () => {
      createComponent();

      const expectedMessage = sprintf(i18n.stepNofN, {
        currentStep: 1,
        stepCount: 3,
      });

      expect(wrapper.findByTestId('step-count').text()).toBe(expectedMessage);
      expect(getGlProgressBarWrapper().exists()).toBe(true);
    });

    it('shows the editor', () => {
      createComponent();

      expect(wrapper.findComponent(YamlEditor).exists()).toBe(true);
    });

    it('shows the editor header with the default filename', () => {
      createComponent();

      const expectedMessage = sprintf(i18n.draft, {
        filename: '.gitlab-ci.yml',
      });

      expect(wrapper.findByTestId('editor-header').text()).toBe(expectedMessage);
    });

    it('shows the editor header with a custom filename', async () => {
      const filename = 'my-file.yml';
      createComponent({
        filename,
      });

      const expectedMessage = sprintf(i18n.draft, {
        filename,
      });

      expect(wrapper.findByTestId('editor-header').text()).toBe(expectedMessage);
    });
  });

  describe('steps', () => {
    const totalSteps = steps.length + 1;

    // **Note** on `expectProgressBarValue`
    // Why are we expecting 50% here and not 66% or even 100%?
    // The reason is mostly a UX thing.
    // First, we count the commit step as an extra step, so that would
    // be 66% by now (2 of 3).
    // But then we add yet another one to the calc, because when we
    // arrived on the second step's page, it's not *completed* (which is
    // what the progress bar indicates). So in that case we're at 33%.
    // Lastly, we want to start out with the progress bar not at zero,
    // because UX research indicates that makes a process like this less
    // intimidating, so we're always adding one step to the value bar
    // (but not to the step counter. Now we're back at 50%.
    describe.each`
      step                                       | navigationEventChain                | expectStepNumber | expectCommitStepShown | expectStepDef | expectProgressBarValue
      ${'initial step'}                          | ${[]}                               | ${1}             | ${false}              | ${steps[0]}   | ${25}
      ${'second step'}                           | ${['next']}                         | ${2}             | ${false}              | ${steps[1]}   | ${50}
      ${'commit step'}                           | ${['next', 'next']}                 | ${3}             | ${true}               | ${null}       | ${75}
      ${'stepping back'}                         | ${['next', 'back']}                 | ${1}             | ${false}              | ${steps[0]}   | ${25}
      ${'clicking next>next>back'}               | ${['next', 'next', 'back']}         | ${2}             | ${false}              | ${steps[1]}   | ${50}
      ${'clicking all the way through and back'} | ${['next', 'next', 'back', 'back']} | ${1}             | ${false}              | ${steps[0]}   | ${25}
    `(
      '$step',
      ({
        navigationEventChain,
        expectStepNumber,
        expectCommitStepShown,
        expectStepDef,
        expectProgressBarValue,
      }) => {
        beforeAll(async () => {
          createComponent();
          for (const emittedValue of navigationEventChain) {
            wrapper.findComponent({ ref: 'step' }).vm.$emit(emittedValue);
            // We have to wait for the next step to be mounted
            // before we can emit the next event, so we have to await
            // inside the loop.
            // eslint-disable-next-line no-await-in-loop
            await nextTick();
          }
        });

        afterAll(() => {
          wrapper.destroy();
        });

        if (expectCommitStepShown) {
          it('does not show the step wrapper', async () => {
            expect(wrapper.findComponent(WizardStep).exists()).toBe(false);
          });

          it('shows the commit step page', () => {
            expect(wrapper.findComponent(CommitStep).exists()).toBe(true);
          });
        } else {
          it('passes the correct step config to the step component', async () => {
            expect(getStepWrapper().props('inputs')).toMatchObject(expectStepDef.inputs);
          });

          it('does not show the commit step page', () => {
            expect(wrapper.findComponent(CommitStep).exists()).toBe(false);
          });
        }

        it('updates the progress bar', () => {
          expect(getGlProgressBarWrapper().attributes('value')).toBe(`${expectProgressBarValue}`);
        });

        it('updates the step number', () => {
          const expectedMessage = sprintf(i18n.stepNofN, {
            currentStep: expectStepNumber,
            stepCount: totalSteps,
          });

          expect(wrapper.findByTestId('step-count').text()).toBe(expectedMessage);
        });
      },
    );
  });

  describe('editor overlay', () => {
    beforeAll(() => {
      createComponent();
    });

    afterAll(() => {
      wrapper.destroy();
    });

    it('initially shows a placeholder', async () => {
      const editorContent = getEditorContent();

      await nextTick();

      expect(editorContent).toBe('foo: $FOO\nbar: $BAR\n');
    });

    it('shows an overlay with help text after setup', () => {
      expect(wrapper.findByTestId('placeholder-overlay').exists()).toBe(true);
      expect(wrapper.findByTestId('filename').text()).toBe('.gitlab-ci.yml');
      expect(wrapper.findByTestId('description').text()).toBe(i18n.overlayMessage);
    });

    it('does not show overlay when content has changed', async () => {
      const newCompiledDoc = new Document({ faa: 'bur' });

      await getStepWrapper().vm.$emit('update:compiled', newCompiledDoc);
      await nextTick();

      const overlay = wrapper.findByTestId('placeholder-overlay');

      expect(overlay.exists()).toBe(false);
    });
  });

  describe('editor updates', () => {
    beforeAll(() => {
      createComponent();
    });

    afterAll(() => {
      wrapper.destroy();
    });

    it('editor reflects changes', async () => {
      const newCompiledDoc = new Document({ faa: 'bur' });
      await getStepWrapper().vm.$emit('update:compiled', newCompiledDoc);

      expect(getEditorContent()).toBe(newCompiledDoc.toString());
    });
  });

  describe('line highlights', () => {
    beforeAll(() => {
      createComponent();
    });

    afterAll(() => {
      wrapper.destroy();
    });

    it('highlight requests by the step get passed on to the editor', async () => {
      const highlight = 'foo';

      await getStepWrapper().vm.$emit('update:highlight', highlight);

      expect(wrapper.getComponent(YamlEditor).props('highlight')).toBe(highlight);
    });

    it('removes the highlight when clicking through to the commit step', async () => {
      // Simulate clicking through all steps until the last one
      await Promise.all(
        steps.map(async () => {
          await getStepWrapper().vm.$emit('next');
          await nextTick();
        }),
      );

      expect(wrapper.getComponent(YamlEditor).props('highlight')).toBe(null);
    });
  });
});
