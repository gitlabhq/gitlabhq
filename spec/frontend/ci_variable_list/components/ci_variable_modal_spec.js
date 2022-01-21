import { GlButton, GlFormInput } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { mockTracking } from 'helpers/tracking_helper';
import CiEnvironmentsDropdown from '~/ci_variable_list/components/ci_environments_dropdown.vue';
import CiVariableModal from '~/ci_variable_list/components/ci_variable_modal.vue';
import { AWS_ACCESS_KEY_ID, EVENT_LABEL, EVENT_ACTION } from '~/ci_variable_list/constants';
import createStore from '~/ci_variable_list/store';
import mockData from '../services/mock_data';
import ModalStub from '../stubs';

Vue.use(Vuex);

describe('Ci variable modal', () => {
  let wrapper;
  let store;
  let trackingSpy;

  const maskableRegex = '^[a-zA-Z0-9_+=/@:.~-]{8,}$';

  const createComponent = (method, options = {}) => {
    store = createStore({ maskableRegex, isGroup: options.isGroup });
    wrapper = method(CiVariableModal, {
      attachTo: document.body,
      stubs: {
        GlModal: ModalStub,
      },
      store,
      ...options,
    });
  };

  const findCiEnvironmentsDropdown = () => wrapper.find(CiEnvironmentsDropdown);
  const findModal = () => wrapper.find(ModalStub);
  const findAddorUpdateButton = () =>
    findModal()
      .findAll(GlButton)
      .wrappers.find((button) => button.props('variant') === 'success');
  const deleteVariableButton = () =>
    findModal()
      .findAll(GlButton)
      .wrappers.find((button) => button.props('variant') === 'danger');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Basic interactions', () => {
    beforeEach(() => {
      createComponent(shallowMount);
    });

    it('button is disabled when no key/value pair are present', () => {
      expect(findAddorUpdateButton().attributes('disabled')).toBeTruthy();
    });
  });

  describe('Adding a new variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
      createComponent(shallowMount);
      jest.spyOn(store, 'dispatch').mockImplementation();
      store.state.variable = variable;
    });

    it('button is enabled when key/value pair are present', () => {
      expect(findAddorUpdateButton().attributes('disabled')).toBeFalsy();
    });

    it('Add variable button dispatches addVariable action', () => {
      findAddorUpdateButton().vm.$emit('click');
      expect(store.dispatch).toHaveBeenCalledWith('addVariable');
    });

    it('Clears the modal state once modal is hidden', () => {
      findModal().vm.$emit('hidden');
      expect(store.dispatch).toHaveBeenCalledWith('clearModal');
    });

    it('should dispatch setVariableProtected when admin settings are configured to protect variables', () => {
      store.state.isProtectedByDefault = true;
      findModal().vm.$emit('shown');

      expect(store.dispatch).toHaveBeenCalledWith('setVariableProtected');
    });
  });

  describe('Adding a new non-AWS variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
      const invalidKeyVariable = {
        ...variable,
        key: 'key',
        value: 'value',
        secret_value: 'secret_value',
      };
      createComponent(mount);
      store.state.variable = invalidKeyVariable;
    });

    it('does not show AWS guidance tip', () => {
      const tip = wrapper.find(`div[data-testid='aws-guidance-tip']`);
      expect(tip.exists()).toBe(true);
      expect(tip.isVisible()).toBe(false);
    });
  });

  describe('Adding a new AWS variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
      const invalidKeyVariable = {
        ...variable,
        key: AWS_ACCESS_KEY_ID,
        value: 'AKIAIOSFODNN7EXAMPLEjdhy',
        secret_value: 'AKIAIOSFODNN7EXAMPLEjdhy',
      };
      createComponent(mount);
      store.state.variable = invalidKeyVariable;
    });

    it('shows AWS guidance tip', () => {
      const tip = wrapper.find(`[data-testid='aws-guidance-tip']`);
      expect(tip.exists()).toBe(true);
      expect(tip.isVisible()).toBe(true);
    });
  });

  describe.each`
    value           | secret            | rendered
    ${'value'}      | ${'secret_value'} | ${false}
    ${'dollar$ign'} | ${'dollar$ign'}   | ${true}
  `('Adding a new variable', ({ value, secret, rendered }) => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
      const invalidKeyVariable = {
        ...variable,
        key: 'key',
        value,
        secret_value: secret,
      };
      createComponent(mount);
      store.state.variable = invalidKeyVariable;
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it(`${rendered ? 'renders' : 'does not render'} the variable reference warning`, () => {
      const warning = wrapper.find(`[data-testid='contains-variable-reference']`);
      expect(warning.exists()).toBe(rendered);
    });
  });

  describe('Editing a variable', () => {
    beforeEach(() => {
      const [variable] = mockData.mockVariables;
      createComponent(shallowMount);
      jest.spyOn(store, 'dispatch').mockImplementation();
      store.state.variableBeingEdited = variable;
    });

    it('button text is Update variable when updating', () => {
      expect(findAddorUpdateButton().text()).toBe('Update variable');
    });

    it('Update variable button dispatches updateVariable with correct variable', () => {
      findAddorUpdateButton().vm.$emit('click');
      expect(store.dispatch).toHaveBeenCalledWith('updateVariable');
    });

    it('Resets the editing state once modal is hidden', () => {
      findModal().vm.$emit('hidden');
      expect(store.dispatch).toHaveBeenCalledWith('resetEditing');
    });

    it('dispatches deleteVariable with correct variable to delete', () => {
      deleteVariableButton().vm.$emit('click');
      expect(store.dispatch).toHaveBeenCalledWith('deleteVariable');
    });
  });

  describe('Environment scope', () => {
    describe('group level variables', () => {
      it('renders the environment dropdown', () => {
        createComponent(shallowMount, {
          isGroup: true,
          provide: {
            glFeatures: {
              groupScopedCiVariables: true,
            },
          },
        });

        expect(findCiEnvironmentsDropdown().exists()).toBe(true);
        expect(findCiEnvironmentsDropdown().isVisible()).toBe(true);
      });

      describe('licensed feature is not available', () => {
        it('disables the dropdown', () => {
          createComponent(mount, {
            isGroup: true,
            provide: {
              glFeatures: {
                groupScopedCiVariables: false,
              },
            },
          });

          const environmentScopeInput = wrapper
            .find('[data-testid="environment-scope"]')
            .find(GlFormInput);
          expect(findCiEnvironmentsDropdown().exists()).toBe(false);
          expect(environmentScopeInput.attributes('readonly')).toBe('readonly');
        });
      });
    });
  });

  describe('Validations', () => {
    const maskError = 'This variable can not be masked.';

    describe('when the mask state is invalid', () => {
      beforeEach(() => {
        const [variable] = mockData.mockVariables;
        const invalidMaskVariable = {
          ...variable,
          key: 'qs',
          value: 'd:;',
          secret_value: 'd:;',
          masked: true,
        };
        createComponent(mount);
        store.state.variable = invalidMaskVariable;
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      it('disables the submit button', () => {
        expect(findAddorUpdateButton().attributes('disabled')).toBeTruthy();
      });

      it('shows the correct error text', () => {
        expect(findModal().text()).toContain(maskError);
      });

      it('sends the correct tracking event', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTION, {
          label: EVENT_LABEL,
          property: ';',
        });
      });
    });

    describe.each`
      value                  | secret                | masked   | eventSent | trackingErrorProperty
      ${'value'}             | ${'secretValue'}      | ${false} | ${0}      | ${null}
      ${'shortMasked'}       | ${'short'}            | ${true}  | ${0}      | ${null}
      ${'withDollar$Sign'}   | ${'dollar$ign'}       | ${false} | ${1}      | ${'$'}
      ${'withDollar$Sign'}   | ${'dollar$ign'}       | ${true}  | ${1}      | ${'$'}
      ${'unsupported'}       | ${'unsupported|char'} | ${true}  | ${1}      | ${'|'}
      ${'unsupportedMasked'} | ${'unsupported|char'} | ${false} | ${0}      | ${null}
    `('Adding a new variable', ({ value, secret, masked, eventSent, trackingErrorProperty }) => {
      beforeEach(() => {
        const [variable] = mockData.mockVariables;
        const invalidKeyVariable = {
          ...variable,
          key: 'key',
          value,
          secret_value: secret,
          masked,
        };
        createComponent(mount);
        store.state.variable = invalidKeyVariable;
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      it(`${
        eventSent > 0 ? 'sends the correct' : 'does not send the'
      } variable validation tracking event`, () => {
        expect(trackingSpy).toHaveBeenCalledTimes(eventSent);

        if (eventSent > 0) {
          expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTION, {
            label: EVENT_LABEL,
            property: trackingErrorProperty,
          });
        }
      });
    });

    describe('when both states are valid', () => {
      beforeEach(() => {
        const [variable] = mockData.mockVariables;
        const validMaskandKeyVariable = {
          ...variable,
          key: AWS_ACCESS_KEY_ID,
          value: '12345678',
          secret_value: '87654321',
          masked: true,
        };
        createComponent(mount);
        store.state.variable = validMaskandKeyVariable;
      });

      it('does not disable the submit button', () => {
        expect(findAddorUpdateButton().attributes('disabled')).toBeFalsy();
      });
    });
  });
});
