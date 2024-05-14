import { nextTick } from 'vue';
import {
  GlDrawer,
  GlFormCombobox,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlLink,
  GlModal,
  GlSprintf,
  GlFormRadio,
  GlFormRadioGroup,
} from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import CiEnvironmentsDropdown from '~/ci/common/private/ci_environments_dropdown';
import CiVariableDrawer from '~/ci/ci_variable_list/components/ci_variable_drawer.vue';
import { awsTokenList } from '~/ci/ci_variable_list/components/ci_variable_autocomplete_tokens';
import {
  ADD_VARIABLE_ACTION,
  DRAWER_EVENT_LABEL,
  EDIT_VARIABLE_ACTION,
  EVENT_ACTION,
  variableOptions,
  projectString,
  variableTypes,
} from '~/ci/ci_variable_list/constants';
import { mockTracking } from 'helpers/tracking_helper';
import { mockVariablesWithScopes } from '../mocks';

describe('CI Variable Drawer', () => {
  let wrapper;
  let trackingSpy;

  const itif = (condition) => (condition ? it : it.skip);

  const mockProjectVariable = mockVariablesWithScopes(projectString)[0];
  const mockProjectVariableFileType = mockVariablesWithScopes(projectString)[1];
  const mockEnvScope = 'staging';
  const mockEnvironments = ['*', 'dev', 'staging', 'production'];

  // matches strings that contain at least 8 consecutive characters consisting of only
  // letters (both uppercase and lowercase), digits, or the specified special characters
  const maskableRegex = '^[a-zA-Z0-9_+=/@:.~-]{8,}$';

  // matches strings that consist of at least 8 or more non-whitespace characters
  const maskableRawRegex = '^\\S{8,}$';

  const defaultProps = {
    areEnvironmentsLoading: false,
    areScopedVariablesAvailable: true,
    environments: mockEnvironments,
    hideEnvironmentScope: false,
    selectedVariable: {},
    mode: ADD_VARIABLE_ACTION,
  };

  const defaultProvide = {
    isProtectedByDefault: true,
    environmentScopeLink: '/help/environments',
    maskableRawRegex,
    maskableRegex,
  };

  const createComponent = ({
    mountFn = shallowMountExtended,
    props = {},
    provide = {},
    stubs = {},
  } = {}) => {
    wrapper = mountFn(CiVariableDrawer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs,
    });
  };

  const findConfirmBtn = () => wrapper.findByTestId('ci-variable-confirm-button');
  const findConfirmDeleteModal = () => wrapper.findComponent(GlModal);
  const findDeleteBtn = () => wrapper.findByTestId('ci-variable-delete-button');
  const findDescriptionField = () => wrapper.findByTestId('ci-variable-description');
  const findDisabledEnvironmentScopeDropdown = () => wrapper.findComponent(GlFormInput);
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findEnvironmentScopeDropdown = () => wrapper.findComponent(CiEnvironmentsDropdown);
  const findExpandedCheckbox = () => wrapper.findByTestId('ci-variable-expanded-checkbox');
  const findFlagsDocsLink = () => wrapper.findByTestId('ci-variable-flags-docs-link');
  const findKeyField = () => wrapper.findComponent(GlFormCombobox);
  const findMaskedRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findMaskedRadioGroup = () => wrapper.findByTestId('ci-variable-masked');
  const findProtectedCheckbox = () => wrapper.findByTestId('ci-variable-protected-checkbox');
  const findValueField = () => wrapper.findByTestId('ci-variable-value');
  const findValueLabel = () => wrapper.findByTestId('ci-variable-value-label');
  const findTitle = () => findDrawer().find('h2');
  const findTypeDropdown = () => wrapper.findComponent(GlFormSelect);
  const findVariablesPrecedenceDocsLink = () =>
    wrapper.findByTestId('ci-variable-precedence-docs-link');

  describe('template', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlFormGroup, GlLink, GlSprintf } });
    });

    it('renders docs link for variables precendece', () => {
      expect(findVariablesPrecedenceDocsLink().attributes('href')).toBe(
        helpPagePath('ci/variables/index', { anchor: 'cicd-variable-precedence' }),
      );
    });

    it('renders docs link for flags', () => {
      expect(findFlagsDocsLink().attributes('href')).toBe(
        helpPagePath('ci/variables/index', { anchor: 'define-a-cicd-variable-in-the-ui' }),
      );
    });

    it('value field is resizable', () => {
      expect(findValueField().props('noResize')).toBe(false);
    });
  });

  describe('validations', () => {
    describe('type dropdown', () => {
      beforeEach(() => {
        createComponent({ mountFn: mountExtended });
      });

      it('adds each type option as a dropdown item', () => {
        expect(findTypeDropdown().findAll('option')).toHaveLength(variableOptions.length);

        variableOptions.forEach((v) => {
          expect(findTypeDropdown().text()).toContain(v.text);
        });
      });

      it('is set to environment variable by default', () => {
        expect(findTypeDropdown().findAll('option').at(0).attributes('value')).toBe(
          variableTypes.envType,
        );
      });

      it('renders the selected variable type', () => {
        createComponent({
          mountFn: mountExtended,
          props: {
            areEnvironmentsLoading: true,
            selectedVariable: mockProjectVariableFileType,
          },
        });

        expect(findTypeDropdown().element.value).toBe(variableTypes.fileType);
      });
    });

    describe('environment scope dropdown', () => {
      it('passes correct props to the dropdown', () => {
        createComponent({
          props: {
            areEnvironmentsLoading: true,
            selectedVariable: { ...mockProjectVariable, environmentScope: mockEnvScope },
          },
          stubs: { CiEnvironmentsDropdown },
        });

        expect(findEnvironmentScopeDropdown().props()).toMatchObject({
          areEnvironmentsLoading: true,
          environments: mockEnvironments,
          selectedEnvironmentScope: mockEnvScope,
        });
      });

      it('hides environment scope dropdown when hideEnvironmentScope is true', () => {
        createComponent({
          props: { hideEnvironmentScope: true },
          stubs: { CiEnvironmentsDropdown },
        });

        expect(findEnvironmentScopeDropdown().exists()).toBe(false);
      });

      it('disables the environment scope dropdown when areScopedVariablesAvailable is false', () => {
        createComponent({
          mountFn: mountExtended,
          props: { areScopedVariablesAvailable: false },
        });

        expect(findEnvironmentScopeDropdown().exists()).toBe(false);
        expect(findDisabledEnvironmentScopeDropdown().attributes('readonly')).toBe('readonly');
      });
    });

    describe('visibility section', () => {
      it('renders radio buttons for Variable masking', () => {
        createComponent({ stubs: { GlFormRadioGroup, GlFormRadio } });

        expect(findMaskedRadioButtons()).toHaveLength(2);
      });

      describe('masked radio', () => {
        beforeEach(() => {
          createComponent();
        });

        it('is false by default', () => {
          expect(findMaskedRadioGroup().attributes('checked')).toBeUndefined();
        });

        it('inherits value of selected variable when editing', () => {
          createComponent({
            props: {
              selectedVariable: mockProjectVariableFileType,
              mode: EDIT_VARIABLE_ACTION,
            },
          });

          expect(findMaskedRadioGroup().attributes('checked')).toBe('true');
        });
      });
    });

    describe('protected flag', () => {
      beforeEach(() => {
        createComponent();
      });

      it('is true by default when isProtectedByDefault is true', () => {
        expect(findProtectedCheckbox().attributes('checked')).toBeDefined();
      });

      it('is not checked when isProtectedByDefault is false', () => {
        createComponent({ provide: { isProtectedByDefault: false } });

        expect(findProtectedCheckbox().attributes('checked')).toBeUndefined();
      });

      it('inherits value of selected variable when editing', () => {
        createComponent({
          props: {
            selectedVariable: mockProjectVariableFileType,
            mode: EDIT_VARIABLE_ACTION,
          },
        });

        expect(findProtectedCheckbox().attributes('checked')).toBeUndefined();
      });
    });

    describe('expanded flag', () => {
      beforeEach(() => {
        createComponent();
      });

      it('is true by default when adding a variable', () => {
        expect(findExpandedCheckbox().attributes('checked')).toBeDefined();
      });

      it('inherits value of selected variable when editing', () => {
        createComponent({
          props: {
            selectedVariable: mockProjectVariableFileType,
            mode: EDIT_VARIABLE_ACTION,
          },
        });

        expect(findExpandedCheckbox().attributes('checked')).toBeUndefined();
      });

      it("sets the variable's raw value", async () => {
        await findKeyField().vm.$emit('input', 'NEW_VARIABLE');
        await findExpandedCheckbox().vm.$emit('change');
        await findConfirmBtn().vm.$emit('click');

        const sentRawValue = wrapper.emitted('add-variable')[0][0].raw;
        expect(sentRawValue).toBe(!defaultProps.raw);
      });

      it('shows help text when variable is not expanded (will be evaluated as raw)', async () => {
        expect(findExpandedCheckbox().attributes('checked')).toBeDefined();
        expect(findDrawer().text()).not.toContain(
          'Variable value will be evaluated as raw string.',
        );

        await findExpandedCheckbox().vm.$emit('change');

        expect(findExpandedCheckbox().attributes('checked')).toBeUndefined();
        expect(findDrawer().text()).toContain('Variable value will be evaluated as raw string.');
      });

      it('shows help text when variable is expanded and contains the $ character', async () => {
        expect(findDrawer().text()).not.toContain(
          'Unselect "Expand variable reference" if you want to use the variable value as a raw string.',
        );

        await findValueField().vm.$emit('input', '$NEW_VALUE');

        expect(findDrawer().text()).toContain(
          'Unselect "Expand variable reference" if you want to use the variable value as a raw string.',
        );
      });
    });

    describe('key', () => {
      beforeEach(() => {
        createComponent();
      });

      it('prompts AWS tokens as options', () => {
        expect(findKeyField().props('tokenList')).toBe(awsTokenList);
      });

      const keyFeedbackMessage = "A variable key can only contain letters, numbers, and '_'.";
      describe.each`
        key                      | feedbackMessage       | submitButtonDisabledState
        ${'validKey123'}         | ${''}                 | ${undefined}
        ${'VALID_KEY'}           | ${''}                 | ${undefined}
        ${''}                    | ${''}                 | ${'true'}
        ${'invalid!!key'}        | ${keyFeedbackMessage} | ${'true'}
        ${'key with whitespace'} | ${keyFeedbackMessage} | ${'true'}
        ${'multiline\nkey'}      | ${keyFeedbackMessage} | ${'true'}
      `('key validation', ({ key, feedbackMessage, submitButtonDisabledState }) => {
        it(`validates key ${key} correctly`, async () => {
          await findKeyField().vm.$emit('input', key);

          expect(findConfirmBtn().attributes('disabled')).toBe(submitButtonDisabledState);
          expect(wrapper.text()).toContain(feedbackMessage);
        });
      });
    });

    describe('value', () => {
      beforeEach(() => {
        createComponent();
      });

      it('can submit empty value', async () => {
        await findKeyField().vm.$emit('input', 'NEW_VARIABLE');

        // value is empty by default
        expect(findConfirmBtn().attributes('disabled')).toBeUndefined();
      });

      const invalidValues = {
        short: 'short',
        multiLine: 'multiline\nvalue',
        unsupportedChar: 'unsupported|char',
        twoUnsupportedChars: 'unsupported|chars!',
        threeUnsupportedChars: '%unsupported|chars!',
        shortAndMultiLine: 'sho\nrt',
        shortAndUnsupportedChar: 'short!',
        shortAndMultiLineAndUnsupportedChar: 'short\n!',
        multiLineAndUnsupportedChar: 'multiline\nvalue!',
      };
      const maskedValidationIssuesText = {
        short: 'The value must have at least 8 characters.',
        multiLine:
          'This value cannot be masked because it contains the following characters: whitespace characters.',
        unsupportedChar:
          'This value cannot be masked because it contains the following characters: |.',
        unsupportedDollarChar:
          'This value cannot be masked because it contains the following characters: $.',
        twoUnsupportedChars:
          'This value cannot be masked because it contains the following characters: |, !.',
        threeUnsupportedChars:
          'This value cannot be masked because it contains the following characters: %, |, !.',
        shortAndMultiLine:
          'This value cannot be masked because it contains the following characters: whitespace characters. The value must have at least 8 characters.',
        shortAndUnsupportedChar:
          'This value cannot be masked because it contains the following characters: !. The value must have at least 8 characters.',
        shortAndMultiLineAndUnsupportedChar:
          'This value cannot be masked because it contains the following characters: ! and whitespace characters. The value must have at least 8 characters.',
        multiLineAndUnsupportedChar:
          'This value cannot be masked because it contains the following characters: ! and whitespace characters.',
      };

      describe.each`
        value                                                | canSubmit | trackingErrorProperty | validationIssueKey
        ${'secretValue'}                                     | ${true}   | ${null}               | ${''}
        ${'~v@lid:symbols.'}                                 | ${true}   | ${null}               | ${''}
        ${invalidValues.short}                               | ${false}  | ${null}               | ${'short'}
        ${invalidValues.multiLine}                           | ${false}  | ${'\n'}               | ${'multiLine'}
        ${'dollar$ign'}                                      | ${false}  | ${'$'}                | ${'unsupportedDollarChar'}
        ${invalidValues.unsupportedChar}                     | ${false}  | ${'|'}                | ${'unsupportedChar'}
        ${invalidValues.twoUnsupportedChars}                 | ${false}  | ${'|!'}               | ${'twoUnsupportedChars'}
        ${invalidValues.threeUnsupportedChars}               | ${false}  | ${'%|!'}              | ${'threeUnsupportedChars'}
        ${invalidValues.shortAndMultiLine}                   | ${false}  | ${'\n'}               | ${'shortAndMultiLine'}
        ${invalidValues.shortAndUnsupportedChar}             | ${false}  | ${'!'}                | ${'shortAndUnsupportedChar'}
        ${invalidValues.shortAndMultiLineAndUnsupportedChar} | ${false}  | ${'\n!'}              | ${'shortAndMultiLineAndUnsupportedChar'}
        ${invalidValues.multiLineAndUnsupportedChar}         | ${false}  | ${'\n!'}              | ${'multiLineAndUnsupportedChar'}
      `(
        'masking requirements',
        ({ value, canSubmit, trackingErrorProperty, validationIssueKey }) => {
          beforeEach(() => {
            createComponent();

            trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
            findKeyField().vm.$emit('input', 'NEW_VARIABLE');
            findValueField().vm.$emit('input', value);
            findMaskedRadioGroup().vm.$emit('input', true);
          });

          itif(canSubmit)(`can submit when value is ${value}`, () => {
            /* eslint-disable jest/no-standalone-expect */
            expect(findValueLabel().attributes('invalid-feedback')).toBe('');
            expect(findConfirmBtn().attributes('disabled')).toBeUndefined();
            /* eslint-enable jest/no-standalone-expect */
          });

          itif(!canSubmit)(
            `shows validation errors and disables submit button when value is ${value}`,
            () => {
              const validationIssueText = maskedValidationIssuesText[validationIssueKey] || '';

              /* eslint-disable jest/no-standalone-expect */
              expect(findValueLabel().attributes('invalid-feedback')).toBe(validationIssueText);
              expect(findConfirmBtn().attributes('disabled')).toBeDefined();
              /* eslint-enable jest/no-standalone-expect */
            },
          );

          itif(trackingErrorProperty)(
            `sends the correct variable validation tracking event when value is ${value}`,
            () => {
              /* eslint-disable jest/no-standalone-expect */
              expect(trackingSpy).toHaveBeenCalledTimes(1);
              expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTION, {
                label: DRAWER_EVENT_LABEL,
                property: trackingErrorProperty,
              });
              /* eslint-enable jest/no-standalone-expect */
            },
          );

          itif(!trackingErrorProperty)(
            `does not send the the correct variable validation tracking event when value is ${value}`,
            () => {
              // eslint-disable-next-line jest/no-standalone-expect
              expect(trackingSpy).toHaveBeenCalledTimes(0);
            },
          );
        },
      );

      it('only sends the tracking event once', async () => {
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        await findKeyField().vm.$emit('input', 'NEW_VARIABLE');
        await findMaskedRadioGroup().vm.$emit('input', true);

        expect(trackingSpy).toHaveBeenCalledTimes(0);

        await findValueField().vm.$emit('input', 'unsupported|char');

        expect(trackingSpy).toHaveBeenCalledTimes(1);

        await findValueField().vm.$emit('input', 'dollar$ign');

        expect(trackingSpy).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('drawer events', () => {
    it('emits `search-environment-scope` before mounting', () => {
      createComponent();

      expect(wrapper.emitted('search-environment-scope')).toHaveLength(1);
      expect(wrapper.emitted('search-environment-scope')).toEqual([['']]);
    });

    it('emits `close-form` when closing the drawer', async () => {
      createComponent();

      expect(wrapper.emitted('close-form')).toBeUndefined();

      await findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close-form')).toHaveLength(1);
    });

    describe('when adding a variable', () => {
      beforeEach(() => {
        createComponent({ stubs: { GlDrawer } });
      });

      it('title and confirm button renders the correct text', () => {
        expect(findTitle().text()).toBe('Add variable');
        expect(findConfirmBtn().text()).toBe('Add variable');
      });

      it('does not render delete button', () => {
        expect(findDeleteBtn().exists()).toBe(false);
      });

      it('dispatches the add-variable event without closing the form', async () => {
        await findDescriptionField().vm.$emit('input', 'NEW_DESCRIPTION');
        await findKeyField().vm.$emit('input', 'NEW_VARIABLE');
        await findProtectedCheckbox().vm.$emit('input', false);
        await findExpandedCheckbox().vm.$emit('input', true);
        await findMaskedRadioGroup().vm.$emit('input', true);
        await findValueField().vm.$emit('input', 'NEW_VALUE');

        findConfirmBtn().vm.$emit('click');

        expect(wrapper.emitted('add-variable')).toEqual([
          [
            {
              environmentScope: '*',
              description: 'NEW_DESCRIPTION',
              key: 'NEW_VARIABLE',
              masked: true,
              protected: false,
              raw: false, // opposite of expanded
              value: 'NEW_VALUE',
              variableType: 'ENV_VAR',
            },
          ],
        ]);
        expect(wrapper.emitted('close-form')).toBeUndefined();
      });
    });

    describe('when editing a variable without closing the form', () => {
      beforeEach(() => {
        createComponent({
          props: { mode: EDIT_VARIABLE_ACTION, selectedVariable: mockProjectVariableFileType },
          stubs: { GlDrawer },
        });
      });

      it('title and confirm button renders the correct text', () => {
        expect(findTitle().text()).toBe('Edit variable');
        expect(findConfirmBtn().text()).toBe('Save changes');
      });

      it('dispatches the edit-variable event', async () => {
        await findValueField().vm.$emit('input', 'EDITED_VALUE');
        await findDescriptionField().vm.$emit('input', 'EDITED_DESCRIPTION');

        findConfirmBtn().vm.$emit('click');

        expect(wrapper.emitted('update-variable')).toEqual([
          [
            {
              ...mockProjectVariableFileType,
              description: 'EDITED_DESCRIPTION',
              value: 'EDITED_VALUE',
            },
          ],
        ]);
        expect(wrapper.emitted('close-form')).toBeUndefined();
      });
    });

    describe('when deleting a variable', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
          props: { mode: EDIT_VARIABLE_ACTION, selectedVariable: mockProjectVariableFileType },
        });
      });

      it('bubbles up the delete-variable event and closes the form', async () => {
        findDeleteBtn().vm.$emit('click');

        await nextTick();

        findConfirmDeleteModal().vm.$emit('primary');

        expect(wrapper.emitted('delete-variable')).toEqual([[mockProjectVariableFileType]]);
        expect(wrapper.emitted('close-form')).toHaveLength(1);
      });
    });

    describe('environment scope events', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
          props: {
            mode: EDIT_VARIABLE_ACTION,
            selectedVariable: mockProjectVariableFileType,
            areScopedVariablesAvailable: true,
            hideEnvironmentScope: false,
          },
        });
      });

      it('sets the environment scope', async () => {
        await findEnvironmentScopeDropdown().vm.$emit('select-environment', 'staging');
        await findConfirmBtn().vm.$emit('click');

        expect(wrapper.emitted('update-variable')).toEqual([
          [
            {
              ...mockProjectVariableFileType,
              environmentScope: 'staging',
            },
          ],
        ]);
      });

      it('bubbles up the search event', async () => {
        await findEnvironmentScopeDropdown().vm.$emit('search-environment-scope', 'staging');

        expect(wrapper.emitted('search-environment-scope')[1]).toEqual(['staging']);
      });
    });
  });
});
