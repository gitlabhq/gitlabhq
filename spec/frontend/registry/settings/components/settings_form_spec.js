import { mount } from '@vue/test-utils';
import Tracking from '~/tracking';
import stubChildren from 'helpers/stub_children';
import component from '~/registry/settings/components/settings_form.vue';
import { createStore } from '~/registry/settings/store/';
import {
  NAME_REGEX_LENGTH,
  UPDATE_SETTINGS_ERROR_MESSAGE,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/registry/settings/constants';
import { stringifiedFormOptions } from '../mock_data';

describe('Settings Form', () => {
  let wrapper;
  let store;
  let dispatchSpy;

  const FORM_ELEMENTS_ID_PREFIX = '#expiration-policy';
  const trackingPayload = {
    label: 'docker_container_retention_and_expiration_policies',
  };

  const GlLoadingIcon = { name: 'gl-loading-icon-stub', template: '<svg></svg>' };

  const findFormGroup = name => wrapper.find(`${FORM_ELEMENTS_ID_PREFIX}-${name}-group`);
  const findFormElements = (name, parent = wrapper) =>
    parent.find(`${FORM_ELEMENTS_ID_PREFIX}-${name}`);
  const findCancelButton = () => wrapper.find({ ref: 'cancel-button' });
  const findSaveButton = () => wrapper.find({ ref: 'save-button' });
  const findForm = () => wrapper.find({ ref: 'form-element' });
  const findLoadingIcon = (parent = wrapper) => parent.find(GlLoadingIcon);

  const mountComponent = (options = {}) => {
    wrapper = mount(component, {
      stubs: {
        ...stubChildren(component),
        GlCard: false,
        GlLoadingIcon,
      },
      mocks: {
        $toast: {
          show: jest.fn(),
        },
      },
      store,
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    store.dispatch('setInitialState', stringifiedFormOptions);
    dispatchSpy = jest.spyOn(store, 'dispatch');
    mountComponent();
    jest.spyOn(Tracking, 'event');
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
  `(
    `${FORM_ELEMENTS_ID_PREFIX}-$elementName form element`,
    ({ elementName, modelName, value, disabledByToggle }) => {
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
        expect(formGroup.attributes('label-align')).toBe(
          `${wrapper.vm.$options.labelsConfig.align}`,
        );
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
    },
  );

  describe('form actions', () => {
    let form;
    beforeEach(() => {
      form = findForm();
    });

    describe('form cancel event', () => {
      it('has type reset', () => {
        expect(findCancelButton().attributes('type')).toBe('reset');
      });

      it('calls the appropriate function', () => {
        dispatchSpy.mockReturnValue();
        form.trigger('reset');
        expect(dispatchSpy).toHaveBeenCalledWith('resetSettings');
      });

      it('tracks the reset event', () => {
        dispatchSpy.mockReturnValue();
        form.trigger('reset');
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'reset_form', trackingPayload);
      });
    });

    it('save has type submit', () => {
      expect(findSaveButton().attributes('type')).toBe('submit');
    });

    describe('when isLoading is true', () => {
      beforeEach(() => {
        store.dispatch('toggleLoading');
      });

      afterEach(() => {
        store.dispatch('toggleLoading');
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

      it('cancel button is disabled', () => {
        expect(findCancelButton().attributes('disabled')).toBeTruthy();
      });
    });

    describe('form submit event ', () => {
      it('calls the appropriate function', () => {
        dispatchSpy.mockResolvedValue();
        form.trigger('submit');
        expect(dispatchSpy).toHaveBeenCalled();
      });

      it('dispatches the saveSettings action', () => {
        dispatchSpy.mockResolvedValue();
        form.trigger('submit');
        expect(dispatchSpy).toHaveBeenCalledWith('saveSettings');
      });

      it('tracks the submit event', () => {
        dispatchSpy.mockResolvedValue();
        form.trigger('submit');
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'submit_form', trackingPayload);
      });

      it('show a success toast when submit succeed', () => {
        dispatchSpy.mockResolvedValue();
        form.trigger('submit');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_SUCCESS_MESSAGE, {
            type: 'success',
          });
        });
      });

      it('show an error toast when submit fails', () => {
        dispatchSpy.mockRejectedValue();
        form.trigger('submit');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.$toast.show).toHaveBeenCalledWith(UPDATE_SETTINGS_ERROR_MESSAGE, {
            type: 'error',
          });
        });
      });
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
      wrapper.setData({ enabled: true });
      return wrapper.vm.$nextTick().then(() => {
        expect(toggleHelpText.html()).toContain('enabled');
      });
    });
  });
});
