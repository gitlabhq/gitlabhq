import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import component from '~/registry/settings/components/settings_form.vue';
import { createStore } from '~/registry/settings/store/';
import { NAME_REGEX_LENGTH } from '~/registry/settings/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Settings Form', () => {
  let wrapper;
  let store;
  let saveSpy;
  let resetSpy;

  const helpPagePath = 'foo';
  const findFormGroup = name => wrapper.find(`#expiration-policy-${name}-group`);
  const findFormElements = (name, father = wrapper) => father.find(`#expiration-policy-${name}`);
  const findCancelButton = () => wrapper.find({ ref: 'cancel-button' });
  const findSaveButton = () => wrapper.find({ ref: 'save-button' });
  const findForm = () => wrapper.find({ ref: 'form-element' });

  const mountComponent = (options = {}) => {
    saveSpy = jest.fn();
    resetSpy = jest.fn();
    wrapper = shallowMount(component, {
      sync: false,
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
    store.dispatch('setInitialState', { helpPagePath });
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe.each`
    elementName        | modelName       | value
    ${'toggle'}        | ${'enabled'}    | ${true}
    ${'interval'}      | ${'older_than'} | ${'foo'}
    ${'schedule'}      | ${'cadence'}    | ${'foo'}
    ${'latest'}        | ${'keep_n'}     | ${'foo'}
    ${'name-matching'} | ${'name_regex'} | ${'foo'}
  `('%s form element', ({ elementName, modelName, value }) => {
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
      element.vm.$emit('input', value);
      expect(wrapper.vm[modelName]).toBe(value);
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
