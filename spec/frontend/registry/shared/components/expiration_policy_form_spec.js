import { mount } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';
import component from '~/registry/shared/components/expiration_policy_form.vue';

import { NAME_REGEX_LENGTH } from '~/registry/shared/constants';
import { formOptions } from '../mock_data';

describe('Expiration Policy Form', () => {
  let wrapper;

  const FORM_ELEMENTS_ID_PREFIX = '#expiration-policy';

  const GlLoadingIcon = { name: 'gl-loading-icon-stub', template: '<svg></svg>' };

  const findFormGroup = name => wrapper.find(`${FORM_ELEMENTS_ID_PREFIX}-${name}-group`);
  const findFormElements = (name, parent = wrapper) =>
    parent.find(`${FORM_ELEMENTS_ID_PREFIX}-${name}`);
  const findCancelButton = () => wrapper.find({ ref: 'cancel-button' });
  const findSaveButton = () => wrapper.find({ ref: 'save-button' });
  const findForm = () => wrapper.find({ ref: 'form-element' });
  const findLoadingIcon = (parent = wrapper) => parent.find(GlLoadingIcon);

  const mountComponent = props => {
    wrapper = mount(component, {
      stubs: {
        ...stubChildren(component),
        GlCard: false,
        GlLoadingIcon,
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
    elementName        | modelName       | value    | disabledByToggle
    ${'toggle'}        | ${'enabled'}    | ${true}  | ${'not disabled'}
    ${'interval'}      | ${'older_than'} | ${'foo'} | ${'disabled'}
    ${'schedule'}      | ${'cadence'}    | ${'foo'} | ${'disabled'}
    ${'latest'}        | ${'keep_n'}     | ${'foo'} | ${'disabled'}
    ${'name-matching'} | ${'name_regex'} | ${'foo'} | ${'disabled'}
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
          expect(wrapper.emitted('input')).toEqual([[{ [modelName]: value }]]);
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

  describe('form actions', () => {
    describe('cancel button', () => {
      it('has type reset', () => {
        mountComponent();
        expect(findCancelButton().attributes('type')).toBe('reset');
      });

      it('is disabled when disableCancelButton is true', () => {
        mountComponent({ disableCancelButton: true });
        return wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe('true');
        });
      });

      it('is disabled isLoading is true', () => {
        mountComponent({ isLoading: true });
        return wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe('true');
        });
      });

      it('is enabled when isLoading and disableCancelButton are false', () => {
        mountComponent({ disableCancelButton: false, isLoading: false });
        return wrapper.vm.$nextTick().then(() => {
          expect(findCancelButton().attributes('disabled')).toBe(undefined);
        });
      });
    });

    describe('form cancel event', () => {
      it('calls the appropriate function', () => {
        mountComponent();
        findForm().trigger('reset');
        expect(wrapper.emitted('reset')).toBeTruthy();
      });
    });

    it('save has type submit', () => {
      mountComponent();
      expect(findSaveButton().attributes('type')).toBe('submit');
    });

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
      `(`${FORM_ELEMENTS_ID_PREFIX}-$elementName is disabled`, ({ elementName }) => {
        expect(findFormElements(elementName).attributes('disabled')).toBe('true');
      });

      it('submit button is disabled and shows a spinner', () => {
        const button = findSaveButton();
        expect(button.attributes('disabled')).toBeTruthy();
        expect(findLoadingIcon(button)).toExist();
      });
    });

    describe('form submit event ', () => {
      it('calls the appropriate function', () => {
        mountComponent();
        findForm().trigger('submit');
        expect(wrapper.emitted('submit')).toBeTruthy();
      });
    });
  });

  describe('form validation', () => {
    describe(`when name regex is longer than ${NAME_REGEX_LENGTH}`, () => {
      const invalidString = new Array(NAME_REGEX_LENGTH + 2).join(',');

      beforeEach(() => {
        mountComponent({ value: { name_regex: invalidString } });
      });

      it('save btn is disabled', () => {
        expect(findSaveButton().attributes('disabled')).toBeTruthy();
      });

      it('nameRegexState is false', () => {
        expect(wrapper.vm.nameRegexState).toBe(false);
      });
    });

    it('if the user did not type validation is null', () => {
      mountComponent({ value: { name_regex: '' } });
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.nameRegexState).toBe(null);
        expect(findSaveButton().attributes('disabled')).toBeFalsy();
      });
    });

    it(`if the user typed and is less than ${NAME_REGEX_LENGTH} state is true`, () => {
      mountComponent({ value: { name_regex: 'foo' } });
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.nameRegexState).toBe(true);
      });
    });
  });

  describe('help text', () => {
    it('toggleDescriptionText show disabled when settings.enabled is false', () => {
      mountComponent();
      const toggleHelpText = findFormGroup('toggle').find('span');
      expect(toggleHelpText.html()).toContain('disabled');
    });

    it('toggleDescriptionText show enabled when settings.enabled is true', () => {
      mountComponent({ value: { enabled: true } });
      const toggleHelpText = findFormGroup('toggle').find('span');
      expect(toggleHelpText.html()).toContain('enabled');
    });
  });
});
