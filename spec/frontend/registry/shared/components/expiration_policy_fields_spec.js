import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import component from '~/registry/shared/components/expiration_policy_fields.vue';

import { NAME_REGEX_LENGTH, ENABLED_TEXT, DISABLED_TEXT } from '~/registry/shared/constants';
import { formOptions } from '../mock_data';

describe('Expiration Policy Form', () => {
  let wrapper;

  const FORM_ELEMENTS_ID_PREFIX = '#expiration-policy';

  const findFormGroup = name => wrapper.find(`${FORM_ELEMENTS_ID_PREFIX}-${name}-group`);
  const findFormElements = (name, parent = wrapper) =>
    parent.find(`${FORM_ELEMENTS_ID_PREFIX}-${name}`);

  const mountComponent = props => {
    wrapper = shallowMount(component, {
      stubs: {
        GlSprintf,
      },
      propsData: {
        formOptions,
        ...props,
      },
      methods: {
        // override idGenerator to avoid having to test with dynamic uid
        idGenerator: value => value,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    mountComponent();
    expect(wrapper.element).toMatchSnapshot();
  });

  describe.each`
    elementName        | modelName          | value    | disabledByToggle
    ${'toggle'}        | ${'enabled'}       | ${true}  | ${'not disabled'}
    ${'interval'}      | ${'olderThan'}     | ${'foo'} | ${'disabled'}
    ${'schedule'}      | ${'cadence'}       | ${'foo'} | ${'disabled'}
    ${'latest'}        | ${'keepN'}         | ${'foo'} | ${'disabled'}
    ${'name-matching'} | ${'nameRegex'}     | ${'foo'} | ${'disabled'}
    ${'keep-name'}     | ${'nameRegexKeep'} | ${'bar'} | ${'disabled'}
  `(
    `${FORM_ELEMENTS_ID_PREFIX}-$elementName form element`,
    ({ elementName, modelName, value, disabledByToggle }) => {
      it(`${elementName} form group exist in the dom`, () => {
        mountComponent();
        const formGroup = findFormGroup(elementName);
        expect(formGroup.exists()).toBe(true);
      });

      it(`${elementName} form group has a label-for property`, () => {
        mountComponent();
        const formGroup = findFormGroup(elementName);
        expect(formGroup.attributes('label-for')).toBe(`expiration-policy-${elementName}`);
      });

      it(`${elementName} form group has a label-cols property`, () => {
        mountComponent({ labelCols: '1' });
        const formGroup = findFormGroup(elementName);
        return wrapper.vm.$nextTick().then(() => {
          expect(formGroup.attributes('label-cols')).toBe('1');
        });
      });

      it(`${elementName} form group has a label-align property`, () => {
        mountComponent({ labelAlign: 'foo' });
        const formGroup = findFormGroup(elementName);
        return wrapper.vm.$nextTick().then(() => {
          expect(formGroup.attributes('label-align')).toBe('foo');
        });
      });

      it(`${elementName} form group contains an input element`, () => {
        mountComponent();
        const formGroup = findFormGroup(elementName);
        expect(findFormElements(elementName, formGroup).exists()).toBe(true);
      });

      it(`${elementName} form element change updated ${modelName} with ${value}`, () => {
        mountComponent();
        const formGroup = findFormGroup(elementName);
        const element = findFormElements(elementName, formGroup);

        const modelUpdateEvent = element.vm.$options.model
          ? element.vm.$options.model.event
          : 'input';
        element.vm.$emit(modelUpdateEvent, value);
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.emitted('input')).toEqual([
            [{ newValue: { [modelName]: value }, modified: modelName }],
          ]);
        });
      });

      it(`${elementName} is ${disabledByToggle} by enabled set to false`, () => {
        mountComponent({ settings: { enabled: false } });
        const formGroup = findFormGroup(elementName);
        const expectation = disabledByToggle === 'disabled' ? 'true' : undefined;
        expect(findFormElements(elementName, formGroup).attributes('disabled')).toBe(expectation);
      });
    },
  );

  describe('when isLoading is true', () => {
    beforeEach(() => {
      mountComponent({ isLoading: true });
    });

    it.each`
      elementName
      ${'toggle'}
      ${'interval'}
      ${'schedule'}
      ${'latest'}
      ${'name-matching'}
      ${'keep-name'}
    `(`${FORM_ELEMENTS_ID_PREFIX}-$elementName is disabled`, ({ elementName }) => {
      expect(findFormElements(elementName).attributes('disabled')).toBe('true');
    });
  });

  describe.each`
    modelName          | elementName
    ${'nameRegex'}     | ${'name-matching'}
    ${'nameRegexKeep'} | ${'keep-name'}
  `('regex textarea validation', ({ modelName, elementName }) => {
    const invalidString = new Array(NAME_REGEX_LENGTH + 2).join(',');

    describe('when apiError contains an error message', () => {
      const errorMessage = 'something went wrong';

      it('shows the error message on the relevant field', () => {
        mountComponent({ apiErrors: { [modelName]: errorMessage } });
        expect(findFormGroup(elementName).attributes('invalid-feedback')).toBe(errorMessage);
      });

      it('gives precedence to API errors compared to local ones', () => {
        mountComponent({
          apiErrors: { [modelName]: errorMessage },
          value: { [modelName]: invalidString },
        });
        expect(findFormGroup(elementName).attributes('invalid-feedback')).toBe(errorMessage);
      });
    });

    describe('when apiErrors is empty', () => {
      it('if the user did not type validation is null', async () => {
        mountComponent({ value: { [modelName]: '' } });
        expect(findFormGroup(elementName).attributes('state')).toBeUndefined();
        expect(wrapper.emitted('validated')).toBeTruthy();
      });

      it(`if the user typed and is less than ${NAME_REGEX_LENGTH} state is true`, () => {
        mountComponent({ value: { [modelName]: 'foo' } });

        const formGroup = findFormGroup(elementName);
        const formElement = findFormElements(elementName, formGroup);
        expect(formGroup.attributes('state')).toBeTruthy();
        expect(formElement.attributes('state')).toBeTruthy();
      });

      describe(`when name regex is longer than ${NAME_REGEX_LENGTH}`, () => {
        beforeEach(() => {
          mountComponent({ value: { [modelName]: invalidString } });
        });

        it('textAreaValidation state is false', () => {
          expect(findFormGroup(elementName).attributes('state')).toBeUndefined();
          // we are forced to check the model attribute because falsy attrs are all casted to undefined in attrs
          // while in this case false shows an error and null instead shows nothing.
          expect(wrapper.vm.textAreaValidation[modelName].state).toBe(false);
        });

        it('emit the @invalidated event', () => {
          expect(wrapper.emitted('invalidated')).toBeTruthy();
        });
      });
    });
  });

  describe('help text', () => {
    it('toggleDescriptionText show disabled when settings.enabled is false', () => {
      mountComponent();
      const toggleHelpText = findFormGroup('toggle').find('span');
      expect(toggleHelpText.html()).toContain(DISABLED_TEXT);
    });

    it('toggleDescriptionText show enabled when settings.enabled is true', () => {
      mountComponent({ value: { enabled: true } });
      const toggleHelpText = findFormGroup('toggle').find('span');
      expect(toggleHelpText.html()).toContain(ENABLED_TEXT);
    });
  });
});
