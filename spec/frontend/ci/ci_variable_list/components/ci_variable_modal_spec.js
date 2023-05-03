import { GlButton, GlFormInput } from '@gitlab/ui';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import CiEnvironmentsDropdown from '~/ci/ci_variable_list/components/ci_environments_dropdown.vue';
import CiVariableModal from '~/ci/ci_variable_list/components/ci_variable_modal.vue';
import {
  ADD_VARIABLE_ACTION,
  AWS_ACCESS_KEY_ID,
  EDIT_VARIABLE_ACTION,
  EVENT_LABEL,
  EVENT_ACTION,
  ENVIRONMENT_SCOPE_LINK_TITLE,
  groupString,
  instanceString,
  projectString,
  variableOptions,
} from '~/ci/ci_variable_list/constants';
import { mockEnvs, mockVariablesWithScopes, mockVariablesWithUniqueScopes } from '../mocks';
import ModalStub from '../stubs';

describe('Ci variable modal', () => {
  let wrapper;
  let trackingSpy;

  const maskableRegex = '^[a-zA-Z0-9_+=/@:.~-]{8,}$';
  const maskableRawRegex = '^\\S{8,}$';

  const mockVariables = mockVariablesWithScopes(instanceString);

  const defaultProvide = {
    awsLogoSvgPath: '/logo',
    awsTipCommandsLink: '/tips',
    awsTipDeployLink: '/deploy',
    awsTipLearnLink: '/learn-link',
    containsVariableReferenceLink: '/reference',
    environmentScopeLink: '/help/environments',
    glFeatures: {
      ciRemoveCharacterLimitationRawMaskedVar: true,
    },
    isProtectedByDefault: false,
    maskedEnvironmentVariablesLink: '/variables-link',
    maskableRawRegex,
    maskableRegex,
  };

  const defaultProps = {
    areEnvironmentsLoading: false,
    areScopedVariablesAvailable: true,
    environments: [],
    hideEnvironmentScope: false,
    mode: ADD_VARIABLE_ACTION,
    selectedVariable: {},
    variables: [],
  };

  const createComponent = ({ mountFn = shallowMountExtended, props = {}, provide = {} } = {}) => {
    wrapper = mountFn(CiVariableModal, {
      attachTo: document.body,
      provide: { ...defaultProvide, ...provide },
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlModal: ModalStub,
      },
    });
  };

  const findCiEnvironmentsDropdown = () => wrapper.findComponent(CiEnvironmentsDropdown);
  const findReferenceWarning = () => wrapper.findByTestId('contains-variable-reference');
  const findModal = () => wrapper.findComponent(ModalStub);
  const findAWSTip = () => wrapper.findByTestId('aws-guidance-tip');
  const findAddorUpdateButton = () => wrapper.findByTestId('ciUpdateOrAddVariableBtn');
  const deleteVariableButton = () =>
    findModal()
      .findAllComponents(GlButton)
      .wrappers.find((button) => button.props('variant') === 'danger');
  const findExpandedVariableCheckbox = () => wrapper.findByTestId('ci-variable-expanded-checkbox');
  const findProtectedVariableCheckbox = () =>
    wrapper.findByTestId('ci-variable-protected-checkbox');
  const findMaskedVariableCheckbox = () => wrapper.findByTestId('ci-variable-masked-checkbox');
  const findValueField = () => wrapper.find('#ci-variable-value');
  const findEnvScopeLink = () => wrapper.findByTestId('environment-scope-link');
  const findEnvScopeInput = () =>
    wrapper.findByTestId('environment-scope').findComponent(GlFormInput);
  const findRawVarTip = () => wrapper.findByTestId('raw-variable-tip');
  const findVariableTypeDropdown = () => wrapper.find('#ci-variable-type');
  const findEnvironmentScopeText = () => wrapper.findByText('Environment scope');

  describe('Adding a variable', () => {
    describe('when no key/value pair are present', () => {
      beforeEach(() => {
        createComponent();
      });

      it('shows the submit button as disabled', () => {
        expect(findAddorUpdateButton().attributes('disabled')).toBeDefined();
      });
    });

    describe('when a key/value pair is present', () => {
      beforeEach(() => {
        createComponent({ props: { selectedVariable: mockVariables[0] } });
      });

      it('shows the submit button as enabled', () => {
        expect(findAddorUpdateButton().attributes('disabled')).toBeUndefined();
      });
    });

    describe('events', () => {
      const [currentVariable] = mockVariables;

      beforeEach(() => {
        createComponent({ props: { selectedVariable: currentVariable } });
      });

      it('Dispatches `add-variable` action on submit', () => {
        findAddorUpdateButton().vm.$emit('click');
        expect(wrapper.emitted('add-variable')).toEqual([[currentVariable]]);
      });

      it('Dispatches the `hideModal` event when dismissing', () => {
        findModal().vm.$emit('hidden');
        expect(wrapper.emitted('hideModal')).toEqual([[]]);
      });
    });
  });

  describe('when protected by default', () => {
    describe('when adding a new variable', () => {
      beforeEach(() => {
        createComponent({ provide: { isProtectedByDefault: true } });
        findModal().vm.$emit('shown');
      });

      it('updates the protected value to true', () => {
        expect(findProtectedVariableCheckbox().attributes('data-is-protected-checked')).toBe(
          'true',
        );
      });
    });

    describe('when editing a variable', () => {
      beforeEach(() => {
        createComponent({
          provide: { isProtectedByDefault: false },
          props: {
            selectedVariable: {},
            mode: EDIT_VARIABLE_ACTION,
          },
        });
        findModal().vm.$emit('shown');
      });

      it('keeps the value as false', () => {
        expect(
          findProtectedVariableCheckbox().attributes('data-is-protected-checked'),
        ).toBeUndefined();
      });
    });
  });

  describe('Adding a new non-AWS variable', () => {
    beforeEach(() => {
      const [variable] = mockVariables;
      createComponent({ mountFn: mountExtended, props: { selectedVariable: variable } });
    });

    it('does not show AWS guidance tip', () => {
      const tip = findAWSTip();
      expect(tip.exists()).toBe(true);
      expect(tip.isVisible()).toBe(false);
    });
  });

  describe('Adding a new AWS variable', () => {
    beforeEach(() => {
      const [variable] = mockVariables;
      const AWSKeyVariable = {
        ...variable,
        key: AWS_ACCESS_KEY_ID,
        value: 'AKIAIOSFODNN7EXAMPLEjdhy',
      };
      createComponent({ mountFn: mountExtended, props: { selectedVariable: AWSKeyVariable } });
    });

    it('shows AWS guidance tip', () => {
      const tip = findAWSTip();
      expect(tip.exists()).toBe(true);
      expect(tip.isVisible()).toBe(true);
    });
  });

  describe('when expanded', () => {
    describe('with a $ character', () => {
      beforeEach(() => {
        const [variable] = mockVariables;
        const variableWithDollarSign = {
          ...variable,
          value: 'valueWith$',
        };
        createComponent({
          mountFn: mountExtended,
          props: { selectedVariable: variableWithDollarSign },
        });
      });

      it(`renders the variable reference warning`, () => {
        expect(findReferenceWarning().exists()).toBe(true);
      });

      it(`does not render raw variable tip`, () => {
        expect(findRawVarTip().exists()).toBe(false);
      });
    });

    describe('without a $ character', () => {
      beforeEach(() => {
        const [variable] = mockVariables;
        createComponent({
          mountFn: mountExtended,
          props: { selectedVariable: variable },
        });
      });

      it(`does not render the variable reference warning`, () => {
        expect(findReferenceWarning().exists()).toBe(false);
      });

      it(`does not render raw variable tip`, () => {
        expect(findRawVarTip().exists()).toBe(false);
      });
    });

    describe('setting raw value', () => {
      const [variable] = mockVariables;

      it('defaults to expanded and raw:false when adding a variable', () => {
        createComponent({ props: { selectedVariable: variable } });

        findModal().vm.$emit('shown');

        expect(findExpandedVariableCheckbox().attributes('checked')).toBe('true');

        findAddorUpdateButton().vm.$emit('click');

        expect(wrapper.emitted('add-variable')).toEqual([
          [
            {
              ...variable,
              raw: false,
            },
          ],
        ]);
      });

      it('sets correct raw value when editing', async () => {
        createComponent({
          props: {
            selectedVariable: variable,
            mode: EDIT_VARIABLE_ACTION,
          },
        });

        findModal().vm.$emit('shown');
        await findExpandedVariableCheckbox().vm.$emit('change');
        await findAddorUpdateButton().vm.$emit('click');

        expect(wrapper.emitted('update-variable')).toEqual([
          [
            {
              ...variable,
              raw: true,
            },
          ],
        ]);
      });
    });
  });

  describe('when not expanded', () => {
    describe('with a $ character', () => {
      beforeEach(() => {
        const selectedVariable = mockVariables[1];
        createComponent({
          mountFn: mountExtended,
          props: { selectedVariable },
        });
      });

      it(`renders raw variable tip`, () => {
        expect(findRawVarTip().exists()).toBe(true);
      });
    });
  });

  describe('Editing a variable', () => {
    const [variable] = mockVariables;

    beforeEach(() => {
      createComponent({ props: { selectedVariable: variable, mode: EDIT_VARIABLE_ACTION } });
    });

    it('button text is Update variable when updating', () => {
      expect(findAddorUpdateButton().text()).toBe('Update variable');
    });

    it('Update variable button dispatches updateVariable with correct variable', () => {
      findAddorUpdateButton().vm.$emit('click');
      expect(wrapper.emitted('update-variable')).toEqual([[variable]]);
    });

    it('Propagates the `hideModal` event', () => {
      findModal().vm.$emit('hidden');
      expect(wrapper.emitted('hideModal')).toEqual([[]]);
    });

    it('dispatches `delete-variable` with correct variable to delete', () => {
      deleteVariableButton().vm.$emit('click');
      expect(wrapper.emitted('delete-variable')).toEqual([[variable]]);
    });
  });

  describe('Environment scope', () => {
    describe('when feature is available', () => {
      describe('and section is not hidden', () => {
        beforeEach(() => {
          createComponent({
            mountFn: mountExtended,
            props: {
              areScopedVariablesAvailable: true,
              hideEnvironmentScope: false,
            },
          });
        });

        it('renders the environment dropdown and section title', () => {
          expect(findCiEnvironmentsDropdown().exists()).toBe(true);
          expect(findCiEnvironmentsDropdown().isVisible()).toBe(true);
          expect(findEnvironmentScopeText().exists()).toBe(true);
        });

        it('renders a link to documentation on scopes', () => {
          const link = findEnvScopeLink();

          expect(link.attributes('title')).toBe(ENVIRONMENT_SCOPE_LINK_TITLE);
          expect(link.attributes('href')).toBe(defaultProvide.environmentScopeLink);
        });

        describe('when feature flag is enabled', () => {
          beforeEach(() => {
            createComponent({
              props: {
                environments: mockEnvs,
                variables: mockVariablesWithUniqueScopes(projectString),
              },
              provide: { glFeatures: { ciLimitEnvironmentScope: true } },
            });
          });

          it('does not merge environment scope sources', () => {
            const expectedLength = mockEnvs.length;

            expect(findCiEnvironmentsDropdown().props('environments')).toHaveLength(expectedLength);
          });
        });

        describe('when feature flag is disabled', () => {
          const mockGroupVariables = mockVariablesWithUniqueScopes(groupString);
          beforeEach(() => {
            createComponent({
              props: {
                environments: mockEnvs,
                variables: mockGroupVariables,
              },
            });
          });

          it('merges environment scope sources', () => {
            const expectedLength = mockGroupVariables.length + mockEnvs.length;

            expect(findCiEnvironmentsDropdown().props('environments')).toHaveLength(expectedLength);
          });
        });
      });

      describe('and section is hidden', () => {
        beforeEach(() => {
          createComponent({
            mountFn: mountExtended,
            props: {
              areScopedVariablesAvailable: true,
              hideEnvironmentScope: true,
            },
          });
        });

        it('does not renders the environment dropdown and section title', () => {
          expect(findCiEnvironmentsDropdown().exists()).toBe(false);
          expect(findEnvironmentScopeText().exists()).toBe(false);
        });
      });
    });

    describe('when feature is not available', () => {
      describe('and section is not hidden', () => {
        beforeEach(() => {
          createComponent({
            mountFn: mountExtended,
            props: {
              areScopedVariablesAvailable: false,
              hideEnvironmentScope: false,
            },
          });
        });

        it('disables the dropdown', () => {
          expect(findCiEnvironmentsDropdown().exists()).toBe(false);
          expect(findEnvironmentScopeText().exists()).toBe(true);
          expect(findEnvScopeInput().attributes('readonly')).toBe('readonly');
        });
      });

      describe('and section is hidden', () => {
        beforeEach(() => {
          createComponent({
            mountFn: mountExtended,
            props: {
              areScopedVariablesAvailable: false,
              hideEnvironmentScope: true,
            },
          });
        });

        it('hides the dropdown', () => {
          expect(findEnvironmentScopeText().exists()).toBe(false);
          expect(findCiEnvironmentsDropdown().exists()).toBe(false);
        });
      });
    });
  });

  describe('variable type dropdown', () => {
    describe('default behaviour', () => {
      beforeEach(() => {
        createComponent({ mountFn: mountExtended });
      });

      it('adds each option as a dropdown item', () => {
        expect(findVariableTypeDropdown().findAll('option')).toHaveLength(variableOptions.length);
        variableOptions.forEach((v) => {
          expect(findVariableTypeDropdown().text()).toContain(v.text);
        });
      });
    });
  });

  describe('Validations', () => {
    const maskError = 'This variable can not be masked.';

    describe('when the variable is raw', () => {
      const [variable] = mockVariables;
      const validRawMaskedVariable = {
        ...variable,
        value: 'd$%^asdsadas',
        masked: false,
        raw: true,
      };

      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
          props: { selectedVariable: validRawMaskedVariable },
        });
      });

      it('should not show an error with symbols', async () => {
        await findMaskedVariableCheckbox().trigger('click');

        expect(findModal().text()).not.toContain(maskError);
      });

      it('should not show an error when length is less than 8', async () => {
        await findValueField().vm.$emit('input', 'a');
        await findMaskedVariableCheckbox().trigger('click');

        expect(findModal().text()).toContain(maskError);
      });
    });

    describe('when the mask state is invalid', () => {
      beforeEach(async () => {
        const [variable] = mockVariables;
        const invalidMaskVariable = {
          ...variable,
          value: 'd:;',
          masked: false,
        };
        createComponent({
          mountFn: mountExtended,
          props: { selectedVariable: invalidMaskVariable },
        });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        await findMaskedVariableCheckbox().trigger('click');
      });

      it('disables the submit button', () => {
        expect(findAddorUpdateButton().attributes('disabled')).toBeDefined();
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
      value                 | masked   | eventSent | trackingErrorProperty
      ${'secretValue'}      | ${false} | ${0}      | ${null}
      ${'short'}            | ${true}  | ${0}      | ${null}
      ${'dollar$ign'}       | ${false} | ${1}      | ${'$'}
      ${'dollar$ign'}       | ${true}  | ${1}      | ${'$'}
      ${'unsupported|char'} | ${true}  | ${1}      | ${'|'}
      ${'unsupported|char'} | ${false} | ${0}      | ${null}
    `('Adding a new variable', ({ value, masked, eventSent, trackingErrorProperty }) => {
      beforeEach(async () => {
        const [variable] = mockVariables;
        const invalidKeyVariable = {
          ...variable,
          value: '',
          masked: false,
        };
        createComponent({
          mountFn: mountExtended,
          props: { selectedVariable: invalidKeyVariable },
        });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        await findValueField().vm.$emit('input', value);
        if (masked) {
          await findMaskedVariableCheckbox().trigger('click');
        }
      });

      it(`${
        eventSent > 0 ? 'sends the correct' : 'does not send the'
      } variable validation tracking event with ${value}`, () => {
        expect(trackingSpy).toHaveBeenCalledTimes(eventSent);

        if (eventSent > 0) {
          expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTION, {
            label: EVENT_LABEL,
            property: trackingErrorProperty,
          });
        }
      });
    });

    describe('when masked variable has acceptable value', () => {
      beforeEach(() => {
        const [variable] = mockVariables;
        const validMaskandKeyVariable = {
          ...variable,
          key: AWS_ACCESS_KEY_ID,
          value: '12345678',
          masked: true,
        };
        createComponent({
          mountFn: mountExtended,
          props: { selectedVariable: validMaskandKeyVariable },
        });
      });

      it('does not disable the submit button', () => {
        expect(findAddorUpdateButton().attributes('disabled')).toBeUndefined();
      });
    });
  });
});
