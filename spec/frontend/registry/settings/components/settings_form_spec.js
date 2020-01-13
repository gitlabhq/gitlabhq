import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import stubChildren from 'helpers/stub_children';
import component from '~/registry/settings/components/settings_form.vue';
import { createStore } from '~/registry/settings/store/';
import { NAME_REGEX_LENGTH } from '~/registry/settings/constants';
import { stringifiedFormOptions } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Settings Form', () => {
  let wrapper;
  let store;
  let saveSpy;
  let resetSpy;

  const findFormGroup = name => wrapper.find(`#expiration-policy-${name}-group`);
  const findFormElements = (name, father = wrapper) => father.find(`#expiration-policy-${name}`);
  const findCancelButton = () => wrapper.find({ ref: 'cancel-button' });
  const findSaveButton = () => wrapper.find({ ref: 'save-button' });
  const findForm = () => wrapper.find({ ref: 'form-element' });

  const mountComponent = (options = {}) => {
    saveSpy = jest.fn();
    resetSpy = jest.fn();
    wrapper = mount(component, {
      stubs: {
        ...stubChildren(component),
        GlCard: false,
      },
      store,
      methods: {
        saveSettings: saveSpy,
        resetSettings: resetSpy,
      },
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    store.dispatch('setInitialState', stringifiedFormOptions);
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe.each`
    elementName        | modelName       | value    | disabledByToggle
    ${'toggle'}        | ${'enabled'}    | ${true}  | ${'not disabled'}
    ${'interval'}      | ${'older_than'} | ${'foo'} | ${'disabled'}
    ${'schedule'}      | ${'cadence'}    | ${'foo'} | ${'disabled'}
    ${'latest'}        | ${'keep_n'}     | ${'foo'} | ${'disabled'}
    ${'name-matching'} | ${'name_regex'} | ${'foo'} | ${'disabled'}
  `('$elementName form element', ({ elementName, modelName, value, disabledByToggle }) => {
    let formGroup;
    beforeEach(() => {
      formGroup = findFormGroup(elementName);
    });
    it(`${elementName} form group exist in the dom`, () => {
      expect(formGroup.exists()).toBe(true);
    });

    it(`${elementName} form group has a label-for property`, () => {
      expect(formGroup.attributes('label-for')).toBe(`expiration-policy-${elementName}`);
    });

    it(`${elementName} form group has a label-cols property`, () => {
      expect(formGroup.attributes('label-cols')).toBe(`${wrapper.vm.$options.labelsConfig.cols}`);
    });

    it(`${elementName} form group has a label-align property`, () => {
      expect(formGroup.attributes('label-align')).toBe(`${wrapper.vm.$options.labelsConfig.align}`);
    });

    it(`${elementName} form group contains an input element`, () => {
      expect(findFormElements(elementName, formGroup).exists()).toBe(true);
    });

    it(`${elementName} form element change updated ${modelName} with ${value}`, () => {
      const element = findFormElements(elementName, formGroup);
      const modelUpdateEvent = element.vm.$options.model
        ? element.vm.$options.model.event
        : 'input';
      element.vm.$emit(modelUpdateEvent, value);
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm[modelName]).toBe(value);
      });
    });

    it(`${elementName} is ${disabledByToggle} by enabled set to false`, () => {
      store.dispatch('updateSettings', { enabled: false });
      const expectation = disabledByToggle === 'disabled' ? 'true' : undefined;
      expect(findFormElements(elementName, formGroup).attributes('disabled')).toBe(expectation);
    });
  });

  describe('form actions', () => {
    let form;
    beforeEach(() => {
      form = findForm();
    });
    it('cancel has type reset', () => {
      expect(findCancelButton().attributes('type')).toBe('reset');
    });

    it('form reset event call the appropriate function', () => {
      form.trigger('reset');
      expect(resetSpy).toHaveBeenCalled();
    });

    it('save has type submit', () => {
      expect(findSaveButton().attributes('type')).toBe('submit');
    });

    it('form submit event call the appropriate function', () => {
      form.trigger('submit');
      expect(saveSpy).toHaveBeenCalled();
    });
  });

  describe('form validation', () => {
    describe(`when name regex is longer than ${NAME_REGEX_LENGTH}`, () => {
      const invalidString = new Array(NAME_REGEX_LENGTH + 2).join(',');
      beforeEach(() => {
        store.dispatch('updateSettings', { name_regex: invalidString });
      });

      it('save btn is disabled', () => {
        expect(findSaveButton().attributes('disabled')).toBeTruthy();
      });

      it('nameRegexState is false', () => {
        expect(wrapper.vm.nameRegexState).toBe(false);
      });
    });

    it('if the user did not type validation is null', () => {
      store.dispatch('updateSettings', { name_regex: null });
      expect(wrapper.vm.nameRegexState).toBe(null);
      return wrapper.vm.$nextTick().then(() => {
        expect(findSaveButton().attributes('disabled')).toBeFalsy();
      });
    });

    it(`if the user typed and is less than ${NAME_REGEX_LENGTH} state is true`, () => {
      store.dispatch('updateSettings', { name_regex: 'abc' });
      expect(wrapper.vm.nameRegexState).toBe(true);
    });
  });

  describe('help text', () => {
    it('toggleDescriptionText text reflects enabled property', () => {
      const toggleHelpText = findFormGroup('toggle').find('span');
      expect(toggleHelpText.html()).toContain('disabled');
      wrapper.vm.enabled = true;
      return wrapper.vm.$nextTick().then(() => {
        expect(toggleHelpText.html()).toContain('enabled');
      });
    });
  });
});
