import { parseDocument, Document } from 'yaml';
import { omit } from 'lodash';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PipelineWizardStep from '~/pipeline_wizard/components/step.vue';
import InputWrapper from '~/pipeline_wizard/components/input_wrapper.vue';
import StepNav from '~/pipeline_wizard/components/step_nav.vue';
import {
  stepInputs,
  stepTemplate,
  compiledYamlBeforeSetup,
  compiledYamlAfterInitialLoad,
  compiledYaml,
} from '../mock/yaml';

describe('Pipeline Wizard - Step Page', () => {
  const inputs = parseDocument(stepInputs).toJS();
  let wrapper;
  let input1;
  let input2;

  const getInputWrappers = () => wrapper.findAllComponents(InputWrapper);
  const forEachInputWrapper = (cb) => {
    getInputWrappers().wrappers.forEach(cb);
  };
  const getStepNav = () => {
    return wrapper.findComponent(StepNav);
  };
  const mockNextClick = () => {
    getStepNav().vm.$emit('next');
  };
  const mockPrevClick = () => {
    getStepNav().vm.$emit('back');
  };
  const expectFalsyAttributeValue = (testedWrapper, attributeName) => {
    expect([false, null, undefined]).toContain(testedWrapper.attributes(attributeName));
  };
  const findInputWrappers = () => {
    const inputWrappers = wrapper.findAllComponents(InputWrapper);
    input1 = inputWrappers.at(0);
    input2 = inputWrappers.at(1);
  };

  const createComponent = (props = {}) => {
    const template = parseDocument(stepTemplate).get('template');
    const defaultProps = {
      inputs,
      template,
    };
    wrapper = shallowMountExtended(PipelineWizardStep, {
      propsData: {
        ...defaultProps,
        compiled: parseDocument(compiledYamlBeforeSetup),
        ...props,
      },
    });
  };

  describe('input children', () => {
    beforeEach(() => {
      createComponent();
    });

    it('mounts an inputWrapper for each input type', () => {
      forEachInputWrapper((inputWrapper, i) =>
        expect(inputWrapper.attributes('widget')).toBe(inputs[i].widget),
      );
    });

    it('passes all unused props to the inputWrapper', () => {
      const pickChildProperties = (from) => {
        return omit(from, ['target', 'widget']);
      };
      forEachInputWrapper((inputWrapper, i) => {
        const expectedProps = pickChildProperties(inputs[i]);
        Object.entries(expectedProps).forEach(([key, value]) => {
          expect(inputWrapper.attributes(key.toLowerCase())).toEqual(value.toString());
        });
      });
    });
  });

  const yamlDocument = new Document({ foo: { bar: 'baz' } });
  const yamlNode = yamlDocument.get('foo');

  describe('prop validation', () => {
    describe.each`
      componentProp | required | valid             | invalid
      ${'inputs'}   | ${true}  | ${[inputs, []]}   | ${[['invalid'], [null], [{}, {}]]}
      ${'template'} | ${true}  | ${[yamlNode]}     | ${['invalid', null, { foo: 1 }, yamlDocument]}
      ${'compiled'} | ${true}  | ${[yamlDocument]} | ${['invalid', null, { foo: 1 }, yamlNode]}
    `('testing `$componentProp` prop', ({ componentProp, required, valid, invalid }) => {
      it('expects prop to be required', () => {
        expect(PipelineWizardStep.props[componentProp].required).toEqual(required);
      });

      it('prop validators return false for invalid types', () => {
        const validatorFunc = PipelineWizardStep.props[componentProp].validator;
        invalid.forEach((invalidType) => {
          expect(validatorFunc(invalidType)).toBe(false);
        });
      });

      it('prop validators return true for valid types', () => {
        const validatorFunc = PipelineWizardStep.props[componentProp].validator;
        valid.forEach((validType) => {
          expect(validatorFunc(validType)).toBe(true);
        });
      });
    });
  });

  describe('navigation', () => {
    it('shows the next button', () => {
      createComponent();

      expect(getStepNav().attributes('nextbuttonenabled')).toEqual('true');
    });

    it('does not show a back button if hasPreviousStep is false', () => {
      createComponent({ hasPreviousStep: false });

      expectFalsyAttributeValue(getStepNav(), 'showbackbutton');
    });

    it('shows a back button if hasPreviousStep is true', () => {
      createComponent({ hasPreviousStep: true });

      expect(getStepNav().attributes('showbackbutton')).toBe('true');
    });

    it('lets "back" event bubble upwards', async () => {
      createComponent();

      await mockPrevClick();
      await nextTick();

      expect(wrapper.emitted().back).toEqual(expect.arrayContaining([]));
    });

    it('lets "next" event bubble upwards', async () => {
      createComponent();

      await mockNextClick();
      await nextTick();

      expect(wrapper.emitted().next).toEqual(expect.arrayContaining([]));
    });
  });

  describe('validation', () => {
    beforeEach(() => {
      createComponent({ hasNextPage: true });
      findInputWrappers();
    });

    it('sets invalid once one input field has an invalid value', async () => {
      input1.vm.$emit('update:valid', true);
      input2.vm.$emit('update:valid', false);

      await mockNextClick();

      expectFalsyAttributeValue(getStepNav(), 'nextbuttonenabled');
    });

    it('returns to valid state once the invalid input is valid again', async () => {
      input1.vm.$emit('update:valid', true);
      input2.vm.$emit('update:valid', false);

      await mockNextClick();

      expectFalsyAttributeValue(getStepNav(), 'nextbuttonenabled');

      input2.vm.$emit('update:valid', true);
      await nextTick();

      expect(getStepNav().attributes('nextbuttonenabled')).toBe('true');
    });

    it('passes validate state to all input wrapper children when next is clicked', async () => {
      forEachInputWrapper((inputWrapper) => {
        expectFalsyAttributeValue(inputWrapper, 'validate');
      });

      await mockNextClick();

      expect(input1.attributes('validate')).toBe('true');
    });

    it('not emitting a valid state is considered valid', async () => {
      // input1 does not emit a update:valid event
      input2.vm.$emit('update:valid', true);

      await mockNextClick();

      expect(getStepNav().attributes('nextbuttonenabled')).toBe('true');
    });
  });

  describe('template compilation', () => {
    beforeEach(() => {
      createComponent();
      findInputWrappers();
    });

    it('injects the template when an input wrapper emits a beforeUpdate:compiled event', () => {
      input1.vm.$emit('beforeUpdate:compiled');

      expect(wrapper.vm.compiled.toString()).toBe(compiledYamlAfterInitialLoad);
    });

    it('lets the "update:compiled" event bubble upwards', async () => {
      const compiled = parseDocument(compiledYaml);

      await input1.vm.$emit('update:compiled', compiled);

      const updateEvents = wrapper.emitted()['update:compiled'];
      const latestUpdateEvent = updateEvents[updateEvents.length - 1];

      expect(latestUpdateEvent[0].toString()).toBe(compiled.toString());
    });
  });
});
