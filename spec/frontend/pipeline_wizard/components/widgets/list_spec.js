import { GlFormGroup, GlFormInputGroup } from '@gitlab/ui';
import { nextTick } from 'vue';
import ListWidget from '~/pipeline_wizard/components/widgets/list.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Pipeline Wizard - List Widget', () => {
  const defaultProps = {
    label: 'This label',
    description: 'some description',
    placeholder: 'some placeholder',
    pattern: '^[a-z]+$',
    invalidFeedback: 'some feedback',
  };
  let wrapper;
  let addStepBtn;

  const findGlFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findGlFormGroupInvalidFeedback = () => findGlFormGroup().find('.invalid-feedback').text();
  const findFirstGlFormInputGroup = () => wrapper.findComponent(GlFormInputGroup);
  const findAllGlFormInputGroups = () => wrapper.findAllComponents(GlFormInputGroup);
  const findGlFormInputGroupByIndex = (index) => findAllGlFormInputGroups().at(index);
  const setValueOnInputField = (value, atIndex = 0) => {
    return findGlFormInputGroupByIndex(atIndex).vm.$emit('input', value);
  };
  const getValueOfInputField = (atIndex = 0) => {
    return findGlFormInputGroupByIndex(atIndex).get('input').element.value;
  };
  const findAddStepButton = () => wrapper.findByTestId('add-step-button');
  const addStep = () => findAddStepButton().vm.$emit('click');

  const createComponent = (props = {}, mountFn = shallowMountExtended) => {
    wrapper = mountFn(ListWidget, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
    addStepBtn = findAddStepButton();
  };

  describe('component setup and interface', () => {
    it('prints the label inside the legend', () => {
      createComponent();

      expect(findGlFormGroup().attributes('label')).toBe(defaultProps.label);
    });

    it('prints the description inside the legend', () => {
      createComponent();

      expect(findGlFormGroup().attributes('labeldescription')).toBe(defaultProps.description);
    });

    it('sets the input field type attribute to "text"', () => {
      createComponent();

      expect(findFirstGlFormInputGroup().attributes('type')).toBe('text');
    });

    it('uses monospace font for input', () => {
      createComponent({ monospace: true });

      expect(findFirstGlFormInputGroup().props('inputClass')).toBe('!gl-font-monospace');
    });

    it('passes the placeholder to the first input field', () => {
      createComponent();

      expect(findFirstGlFormInputGroup().attributes('placeholder')).toBe(defaultProps.placeholder);
    });

    it('shows a delete button on all fields if there are more than one', async () => {
      createComponent({}, mountExtended);

      await addStep();
      await addStep();
      const inputGroups = findAllGlFormInputGroups().wrappers;

      expect(inputGroups.length).toBe(3);
      inputGroups.forEach((inputGroup) => {
        const button = inputGroup.find('[data-testid="remove-step-button"]');
        expect(button.find('[data-testid="remove-icon"]').exists()).toBe(true);
        expect(button.attributes('aria-label')).toBe('remove step');
      });
    });

    it('null values do not cause an input event', async () => {
      createComponent();

      await addStep();

      expect(wrapper.emitted('input')).toBe(undefined);
    });

    it('hides the delete button if there is only one', () => {
      createComponent({}, mountExtended);

      const inputGroups = findAllGlFormInputGroups().wrappers;

      expect(inputGroups.length).toBe(1);
      expect(wrapper.findByTestId('remove-step-button').exists()).toBe(false);
    });

    it('shows an "add step" button', () => {
      createComponent();

      expect(addStepBtn.attributes('icon')).toBe('plus');
      expect(addStepBtn.text()).toBe('add another step');
    });

    it('deletes the correct input item', async () => {
      createComponent({}, mountExtended);

      await addStep();
      await addStep();
      setValueOnInputField('foo', 0);
      setValueOnInputField('bar', 1);
      setValueOnInputField('baz', 2);

      const button = findAllGlFormInputGroups().at(1).find('[data-testid="remove-step-button"]');

      button.vm.$emit('click');
      await nextTick();

      expect(getValueOfInputField(0)).toBe('foo');
      expect(getValueOfInputField(1)).toBe('baz');
    });

    it('the "add step" button increases the number of input fields', async () => {
      createComponent();

      expect(findAllGlFormInputGroups().wrappers.length).toBe(1);
      await addStep();
      expect(findAllGlFormInputGroups().wrappers.length).toBe(2);
    });

    it('does not pass the placeholder on subsequent input fields', async () => {
      createComponent();

      await addStep();
      await addStep();
      const nullOrUndefined = [null, undefined];
      expect(nullOrUndefined).toContain(findAllGlFormInputGroups().at(1).attributes('placeholder'));
      expect(nullOrUndefined).toContain(findAllGlFormInputGroups().at(2).attributes('placeholder'));
    });

    it('emits an update event on input', async () => {
      createComponent();

      const localValue = 'somevalue';
      await setValueOnInputField(localValue);
      await nextTick();

      expect(wrapper.emitted('input')).toEqual([[[localValue]]]);
    });

    it('only emits non-null values', async () => {
      createComponent();

      await addStep();
      await addStep();
      await setValueOnInputField('abc', 1);
      await nextTick();

      const events = wrapper.emitted('input');

      expect(events.length).toBe(1);
      expect(events[0]).toEqual([['abc']]);
    });
  });

  describe('form validation', () => {
    it('does not show validation state when untouched', () => {
      createComponent({}, mountExtended);
      expect(findGlFormGroup().classes()).not.toContain('is-valid');
      expect(findGlFormGroup().classes()).not.toContain('is-invalid');
    });

    it('shows invalid state on blur', async () => {
      createComponent({}, mountExtended);
      expect(findGlFormGroup().classes()).not.toContain('is-invalid');
      const input = findFirstGlFormInputGroup().find('input');
      await input.setValue('invalid99');
      await input.trigger('blur');
      expect(input.classes()).toContain('is-invalid');
      expect(findGlFormGroup().classes()).toContain('is-invalid');
    });

    it('shows invalid state when toggling `validate` prop', async () => {
      createComponent({ required: true, validate: false }, mountExtended);
      await setValueOnInputField(null);
      expect(findGlFormGroup().classes()).not.toContain('is-invalid');
      await wrapper.setProps({ validate: true });
      expect(findGlFormGroup().classes()).toContain('is-invalid');
    });

    it.each`
      scenario                                                           | required | values           | inputFieldClasses             | inputGroupClass | feedback
      ${'shows invalid if all inputs are empty'}                         | ${true}  | ${[null, null]}  | ${['is-invalid', null]}       | ${'is-invalid'} | ${'At least one entry is required'}
      ${'is valid if at least one field has a valid entry'}              | ${true}  | ${[null, 'abc']} | ${[null, 'is-valid']}         | ${'is-valid'}   | ${expect.anything()}
      ${'is invalid if one field has an invalid entry'}                  | ${true}  | ${['abc', '99']} | ${['is-valid', 'is-invalid']} | ${'is-invalid'} | ${defaultProps.invalidFeedback}
      ${'is not invalid if its not required but all values are null'}    | ${false} | ${[null, null]}  | ${[null, null]}               | ${'is-valid'}   | ${expect.anything()}
      ${'is invalid if pattern does not match even if its not required'} | ${false} | ${['99', null]}  | ${['is-invalid', null]}       | ${'is-invalid'} | ${defaultProps.invalidFeedback}
    `('$scenario', async ({ required, values, inputFieldClasses, inputGroupClass, feedback }) => {
      createComponent({ required, validate: true }, mountExtended);

      await Promise.all(
        values.map(async (value, i) => {
          if (i > 0) {
            await addStep();
          }
          await setValueOnInputField(value, i);
        }),
      );
      await nextTick();

      inputFieldClasses.forEach((expected, i) => {
        const inputWrapper = findGlFormInputGroupByIndex(i).find('input');
        if (expected === null) {
          expect(inputWrapper.classes()).not.toContain('is-valid');
          expect(inputWrapper.classes()).not.toContain('is-invalid');
        } else {
          expect(inputWrapper.classes()).toContain(expected);
        }
      });

      expect(findGlFormGroup().classes()).toContain(inputGroupClass);
      expect(findGlFormGroupInvalidFeedback()).toEqual(feedback);
    });
  });
});
