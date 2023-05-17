import { Document, parseDocument } from 'yaml';
import { GlProgressBar } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import PipelineWizardWrapper, { i18n } from '~/pipeline_wizard/components/wrapper.vue';
import WizardStep from '~/pipeline_wizard/components/step.vue';
import CommitStep from '~/pipeline_wizard/components/commit.vue';
import YamlEditor from '~/pipeline_wizard/components/editor.vue';
import { sprintf } from '~/locale';
import {
  steps as stepsYaml,
  compiledScenario1,
  compiledScenario2,
  compiledScenario3,
} from '../mock/yaml';

describe('Pipeline Wizard - wrapper.vue', () => {
  let wrapper;
  const steps = parseDocument(stepsYaml).toJS();

  const getAsYamlNode = (value) => new Document(value).contents;
  const templateId = 'my-namespace/my-template';
  const createComponent = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(PipelineWizardWrapper, {
      propsData: {
        templateId,
        projectPath: '/user/repo',
        defaultBranch: 'main',
        filename: '.gitlab-ci.yml',
        steps: getAsYamlNode(steps),
        ...props,
      },
      stubs: {
        CommitStep: true,
      },
    });
  };
  const getEditorContent = () => {
    return wrapper.getComponent(YamlEditor).props().doc.toString();
  };
  const getStepWrapper = () =>
    wrapper.findAllComponents(WizardStep).wrappers.find((w) => w.isVisible());
  const getGlProgressBarWrapper = () => wrapper.getComponent(GlProgressBar);
  const findFirstVisibleStep = () =>
    wrapper.findAllComponents('[data-testid="step"]').wrappers.find((w) => w.isVisible());
  const findFirstInputFieldForTarget = (target) =>
    wrapper.find(`[data-input-target="${target}"]`).find('input');

  describe('display', () => {
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

    it('shows the editor header with a custom filename', () => {
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
        beforeEach(async () => {
          createComponent();

          for (const emittedValue of navigationEventChain) {
            findFirstVisibleStep().vm.$emit(emittedValue);
            // We have to wait for the next step to be mounted
            // before we can emit the next event, so we have to await
            // inside the loop.
            // eslint-disable-next-line no-await-in-loop
            await nextTick();
          }
        });

        if (expectCommitStepShown) {
          it('does not show the step wrapper', () => {
            expect(wrapper.findComponent(WizardStep).isVisible()).toBe(false);
          });

          it('shows the commit step page', () => {
            expect(wrapper.findComponent(CommitStep).isVisible()).toBe(true);
          });
        } else {
          it('passes the correct step config to the step component', () => {
            expect(getStepWrapper().props('inputs')).toMatchObject(expectStepDef.inputs);
          });

          it('does not show the commit step page', () => {
            expect(wrapper.findComponent(CommitStep).isVisible()).toBe(false);
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
    beforeEach(() => {
      createComponent();
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

    it('editor reflects changes', async () => {
      const newCompiledDoc = new Document({ faa: 'bur' });
      await getStepWrapper().vm.$emit('update:compiled', newCompiledDoc);

      expect(getEditorContent()).toBe(newCompiledDoc.toString());
    });
  });

  describe('line highlights', () => {
    beforeEach(() => {
      createComponent();
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

  describe('integration test', () => {
    beforeEach(() => {
      createComponent({}, mountExtended);
    });

    it('updates the editor content after input on step 1', async () => {
      findFirstInputFieldForTarget('$FOO').setValue('fooVal');
      await nextTick();

      expect(getEditorContent()).toBe(compiledScenario1);
    });

    it('updates the editor content after input on step 2', async () => {
      findFirstVisibleStep().vm.$emit('next');
      await nextTick();

      findFirstInputFieldForTarget('$BAR').setValue('barVal');
      await nextTick();

      expect(getEditorContent()).toBe(compiledScenario2);
    });

    describe('navigating back', () => {
      let inputField;

      beforeEach(async () => {
        createComponent({}, mountExtended);

        findFirstInputFieldForTarget('$FOO').setValue('fooVal');
        await nextTick();

        findFirstVisibleStep().vm.$emit('next');
        await nextTick();

        findFirstInputFieldForTarget('$BAR').setValue('barVal');
        await nextTick();

        findFirstVisibleStep().vm.$emit('back');
        await nextTick();

        inputField = findFirstInputFieldForTarget('$FOO');
      });

      afterEach(() => {
        inputField = undefined;
      });

      it('still shows the input values from the former visit', () => {
        expect(inputField.element.value).toBe('fooVal');
      });

      it('updates the editor content without modifying input that came from a later step', async () => {
        inputField.setValue('newFooVal');
        await nextTick();

        expect(getEditorContent()).toBe(compiledScenario3);
      });
    });
  });

  describe('when commit step done', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits done', () => {
      expect(wrapper.emitted('done')).toBeUndefined();

      wrapper.findComponent(CommitStep).vm.$emit('done');

      expect(wrapper.emitted('done')).toHaveLength(1);
    });
  });

  describe('tracking', () => {
    let trackingSpy;
    const trackingCategory = `pipeline_wizard:${templateId}`;

    const setUpTrackingSpy = () => {
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    };

    it('tracks next button click event', () => {
      createComponent();
      setUpTrackingSpy();
      findFirstVisibleStep().vm.$emit('next');

      expect(trackingSpy).toHaveBeenCalledWith(trackingCategory, 'click_button', {
        category: trackingCategory,
        property: 'next',
        label: 'pipeline_wizard_navigation',
        extra: {
          fromStep: 0,
          toStep: 1,
          features: expect.any(Object),
        },
      });
    });

    it('tracks back button click event', () => {
      createComponent();

      // Navigate to step 1 without the spy set up
      findFirstVisibleStep().vm.$emit('next');

      // Now enable the tracking spy
      setUpTrackingSpy();

      findFirstVisibleStep().vm.$emit('back');

      expect(trackingSpy).toHaveBeenCalledWith(trackingCategory, 'click_button', {
        category: trackingCategory,
        property: 'back',
        label: 'pipeline_wizard_navigation',
        extra: {
          fromStep: 1,
          toStep: 0,
          features: expect.any(Object),
        },
      });
    });

    it('tracks back button click event on the commit step', () => {
      createComponent();

      // Navigate to step 2 without the spy set up
      findFirstVisibleStep().vm.$emit('next');
      findFirstVisibleStep().vm.$emit('next');

      // Now enable the tracking spy
      setUpTrackingSpy();

      wrapper.findComponent(CommitStep).vm.$emit('back');

      expect(trackingSpy).toHaveBeenCalledWith(trackingCategory, 'click_button', {
        category: trackingCategory,
        property: 'back',
        label: 'pipeline_wizard_navigation',
        extra: {
          fromStep: 2,
          toStep: 1,
          features: expect.any(Object),
        },
      });
    });

    it('tracks done event on the commit step', () => {
      createComponent();

      // Navigate to step 2 without the spy set up
      findFirstVisibleStep().vm.$emit('next');
      findFirstVisibleStep().vm.$emit('next');

      // Now enable the tracking spy
      setUpTrackingSpy();

      wrapper.findComponent(CommitStep).vm.$emit('done');

      expect(trackingSpy).toHaveBeenCalledWith(trackingCategory, 'click_button', {
        category: trackingCategory,
        label: 'pipeline_wizard_commit',
        property: 'commit',
        extra: {
          features: expect.any(Object),
        },
      });
    });

    it('tracks when editor emits touch events', () => {
      createComponent();
      setUpTrackingSpy();

      wrapper.findComponent(YamlEditor).vm.$emit('touch');

      expect(trackingSpy).toHaveBeenCalledWith(trackingCategory, 'edit', {
        category: trackingCategory,
        label: 'pipeline_wizard_editor_interaction',
        extra: {
          currentStep: 0,
          features: expect.any(Object),
        },
      });
    });
  });
});
