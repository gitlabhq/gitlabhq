import { nextTick } from 'vue';
import {
  GlDrawer,
  GlFormCombobox,
  GlFormGroup,
  GlFormInput,
  GlCollapsibleListbox,
  GlLink,
  GlModal,
  GlSprintf,
  GlFormRadio,
  GlFormRadioGroup,
  GlPopover,
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
  VISIBILITY_HIDDEN,
  VISIBILITY_MASKED,
  VISIBILITY_VISIBLE,
  projectString,
  variableTypes,
} from '~/ci/ci_variable_list/constants';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
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
    areHiddenVariablesAvailable: true,
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
  const findKeyField = () => wrapper.findComponent(GlFormCombobox);
  const findVisibilityRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findVisibilityRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findProtectedCheckbox = () => wrapper.findByTestId('ci-variable-protected-checkbox');
  const findValueField = () => wrapper.findByTestId('ci-variable-value');
  const findValueLabel = () => wrapper.findByTestId('ci-variable-value-label');
  const findHiddenVariableTip = () => wrapper.findByTestId('hidden-variable-tip');
  const findTitle = () => findDrawer().find('h2');
  const findTypeDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findVariablesPrecedenceDocsLink = () =>
    wrapper.findByTestId('ci-variable-precedence-docs-link');
  const findVisibilityLabelHelpContainer = () =>
    wrapper.findByTestId('visibility-popover-container');
  const findVisibilityLabelHelpPopover = () =>
    findVisibilityLabelHelpContainer().findComponent(GlPopover);
  const findEnvironmentsLabelHelpContainer = () =>
    wrapper.findByTestId('environments-popover-container');
  const findEnvironmentsLabelHelpPopover = () =>
    findEnvironmentsLabelHelpContainer().findComponent(GlPopover);

  describe('template', () => {
    beforeEach(() => {
      createComponent({ stubs: { GlFormGroup, GlLink, GlSprintf } });
    });

    it('renders docs link for variables precendece', () => {
      expect(findVariablesPrecedenceDocsLink().attributes('href')).toBe(
        helpPagePath('ci/variables/_index', { anchor: 'cicd-variable-precedence' }),
      );
    });

    it('value field is resizable', () => {
      expect(findValueField().props('noResize')).toBe(false);
    });

    describe('environments label', () => {
      it('has a help icon', () => {
        const helpIcon = findEnvironmentsLabelHelpContainer().findComponent(HelpIcon);

        expect(helpIcon.exists()).toBe(true);
      });

      it('has a popover', () => {
        const popover = findEnvironmentsLabelHelpPopover();

        expect(popover.exists()).toBe(true);
        expect(popover.props()).toMatchObject({
          target: 'environments-popover-target',
          container: 'environments-popover-container',
        });
      });

      describe('popover', () => {
        it('renders the correct content', () => {
          const popover = findEnvironmentsLabelHelpPopover();

          expect(popover.text()).toContain(
            'You can use a specific environment name like production, or include a wildcard (*) to match multiple environments, like review*.  Learn how to restrict CI/CD variables to specific environments for better security.',
          );
        });

        it('renders the documentation link', () => {
          const popover = findEnvironmentsLabelHelpPopover();
          const link = popover.findComponent(GlLink);
          const documentationLink = helpPagePath('ci/environments/_index', {
            anchor: 'limit-the-environment-scope-of-a-cicd-variable',
          });

          expect(link.attributes('href')).toBe(documentationLink);
        });
      });
    });

    describe('visibility label', () => {
      it('has a help icon', () => {
        const helpIcon = findVisibilityLabelHelpContainer().findComponent(HelpIcon);

        expect(helpIcon.exists()).toBe(true);
      });

      it('has a popover', () => {
        const popover = findVisibilityLabelHelpPopover();

        expect(popover.exists()).toBe(true);
        expect(popover.props()).toMatchObject({
          target: 'visibility-popover-target',
          container: 'visibility-popover-container',
        });
      });

      describe('popover', () => {
        it('renders the correct content', () => {
          const popover = findVisibilityLabelHelpPopover();

          expect(popover.text()).toContain(
            "Set the visibility level for the variable's value. The Masked and hidden option is only available for new variables. You cannot update an existing variable to be hidden.",
          );
        });

        it('renders the documentation link', () => {
          const popover = findVisibilityLabelHelpPopover();
          const link = popover.findComponent(GlLink);
          const documentationLink = helpPagePath('ci/variables/_index', {
            anchor: 'hide-a-cicd-variable',
          });

          expect(link.attributes('href')).toBe(documentationLink);
        });
      });
    });
  });

  describe('validations', () => {
    describe('type dropdown', () => {
      beforeEach(() => {
        createComponent({ mountFn: mountExtended });
      });

      it('adds each type option as a dropdown item', () => {
        expect(findTypeDropdown().props('items')).toHaveLength(variableOptions.length);

        variableOptions.forEach((v) => {
          expect(findTypeDropdown().text()).toContain(v.text);
        });
      });

      it('is set to environment variable by default', () => {
        expect(findTypeDropdown().props('items')[0].value).toBe(variableTypes.envType);
      });

      it('renders the selected variable type', () => {
        createComponent({
          mountFn: shallowMountExtended,
          props: {
            areEnvironmentsLoading: true,
            selectedVariable: mockProjectVariableFileType,
          },
        });

        expect(findTypeDropdown().props('selected')).toBe(variableTypes.fileType);
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
        expect(findDisabledEnvironmentScopeDropdown().attributes('readonly')).toBeDefined();
      });
    });

    describe('visibility section', () => {
      it('renders two radio buttons when areHiddenVariablesAvailable is false', () => {
        createComponent({
          props: { areHiddenVariablesAvailable: false },
        });

        expect(findVisibilityRadioButtons()).toHaveLength(2);
      });

      it('renders three radio buttons when areHiddenVariablesAvailable is true', () => {
        createComponent({
          props: { areHiddenVariablesAvailable: true },
        });

        expect(findVisibilityRadioButtons()).toHaveLength(3);
      });

      describe('radio button behavior', () => {
        beforeEach(() => {
          createComponent({ props: { areHiddenVariablesAvailable: true } });
        });

        it('is set to visible by default', () => {
          expect(findVisibilityRadioGroup().attributes('checked')).toBe(VISIBILITY_VISIBLE);
        });

        it.each`
          description            | masked   | hidden   | expectedVisibility
          ${'visible'}           | ${false} | ${false} | ${VISIBILITY_VISIBLE}
          ${'masked'}            | ${true}  | ${false} | ${VISIBILITY_MASKED}
          ${'masked and hidden'} | ${true}  | ${true}  | ${VISIBILITY_HIDDEN}
        `(
          'selects $description visibility when masked is $masked and hidden is $hidden',
          async ({ masked, hidden, expectedVisibility }) => {
            await createComponent({
              props: {
                selectedVariable: {
                  ...mockProjectVariableFileType,
                  ...{ masked, hidden },
                },
                mode: EDIT_VARIABLE_ACTION,
              },
            });

            expect(findVisibilityRadioGroup().attributes('checked')).toBe(expectedVisibility);
          },
        );

        it('is updated on variable update', async () => {
          await createComponent({
            props: {
              selectedVariable: {
                ...mockProjectVariableFileType,
                masked: true,
                hidden: true,
              },
            },
          });

          expect(findVisibilityRadioGroup().attributes('checked')).toBe(VISIBILITY_HIDDEN);
          await wrapper.setProps({ mutationResponse: { message: 'Success', hasError: false } });

          expect(findVisibilityRadioGroup().attributes('checked')).toBe(VISIBILITY_VISIBLE);
        });
      });

      it('is disabled when editing a hidden variable', () => {
        createComponent({
          props: {
            areHiddenVariablesAvailable: true,
            selectedVariable: { ...mockProjectVariable, hidden: true },
            mode: EDIT_VARIABLE_ACTION,
          },
        });

        expect(findVisibilityRadioGroup().attributes().disabled).toBe('true');
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
        findKeyField().vm.$emit('input', 'NEW_VARIABLE');
        findExpandedCheckbox().vm.$emit('change');
        findConfirmBtn().vm.$emit('click');

        await nextTick();

        const sentRawValue = wrapper.emitted('add-variable')[0][0].raw;
        expect(sentRawValue).toBe(!defaultProps.raw);
      });

      it('shows help text when variable is not expanded (will be evaluated as raw)', async () => {
        expect(findExpandedCheckbox().attributes('checked')).toBeDefined();
        expect(findDrawer().text()).not.toContain(
          'Variable value will be evaluated as raw string.',
        );

        findExpandedCheckbox().vm.$emit('change');

        await nextTick();

        expect(findExpandedCheckbox().attributes('checked')).toBeUndefined();
        expect(findDrawer().text()).toContain('Variable value will be evaluated as raw string.');
      });

      it('shows help text when variable is expanded and contains the $ character', async () => {
        expect(findDrawer().text()).not.toContain(
          'Unselect "Expand variable reference" if you want to use the variable value as a raw string.',
        );

        findValueField().vm.$emit('input', '$NEW_VALUE');

        await nextTick();

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
          findKeyField().vm.$emit('input', key);

          await nextTick();

          expect(findConfirmBtn().attributes().disabled).toBe(submitButtonDisabledState);
          expect(wrapper.text()).toContain(feedbackMessage);
        });
      });
    });

    describe('value', () => {
      beforeEach(() => {
        createComponent();
      });

      it('can submit empty value', async () => {
        findKeyField().vm.$emit('input', 'NEW_VARIABLE');

        await nextTick();

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
            findVisibilityRadioGroup().vm.$emit('change', VISIBILITY_MASKED);
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
        findKeyField().vm.$emit('input', 'NEW_VARIABLE');
        findVisibilityRadioGroup().vm.$emit('change', VISIBILITY_MASKED);

        await nextTick();

        expect(trackingSpy).toHaveBeenCalledTimes(0);

        findValueField().vm.$emit('input', 'unsupported|char');

        await nextTick();

        expect(trackingSpy).toHaveBeenCalledTimes(1);

        findValueField().vm.$emit('input', 'dollar$ign');

        await nextTick();

        expect(trackingSpy).toHaveBeenCalledTimes(1);
      });

      it('when creating a hidden variable, value field behaves like a masked variable', async () => {
        createComponent();

        findKeyField().vm.$emit('input', 'NEW_VARIABLE');
        findValueField().vm.$emit('input', '~v@lid:symbols.');
        findVisibilityRadioGroup().vm.$emit('change', VISIBILITY_HIDDEN);

        await nextTick();

        expect(findHiddenVariableTip().exists()).toBe(false);
        expect(findValueLabel().attributes('invalid-feedback')).toBe('');
        expect(findConfirmBtn().attributes('disabled')).toBeUndefined();

        findValueField().vm.$emit('input', 'dollar$ign');

        await nextTick();

        expect(findHiddenVariableTip().exists()).toBe(false);
        expect(findValueLabel().attributes('invalid-feedback')).not.toBe('');
        expect(findConfirmBtn().attributes('disabled')).toBeDefined();
      });

      it('when editing a hidden variable, value field is replaced with a hint', () => {
        createComponent({
          props: {
            mode: EDIT_VARIABLE_ACTION,
            selectedVariable: { ...mockProjectVariable, hidden: true },
          },
        });

        expect(findValueField().exists()).toBe(false);
        expect(findHiddenVariableTip().text()).toBe('The value is masked and hidden permanently.');
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

      findDrawer().vm.$emit('close');

      await nextTick();

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
        findDescriptionField().vm.$emit('input', 'NEW_DESCRIPTION');
        findKeyField().vm.$emit('input', 'NEW_VARIABLE');
        findProtectedCheckbox().vm.$emit('input', false);
        findExpandedCheckbox().vm.$emit('input', true);
        findVisibilityRadioGroup().vm.$emit('change', VISIBILITY_MASKED);
        findValueField().vm.$emit('input', 'NEW_VALUE');
        findConfirmBtn().vm.$emit('click');

        await nextTick();

        expect(wrapper.emitted('add-variable')).toMatchObject([
          [
            {
              environmentScope: '*',
              description: 'NEW_DESCRIPTION',
              key: 'NEW_VARIABLE',
              masked: true,
              hidden: false,
              protected: false,
              raw: false, // opposite of expanded
              value: 'NEW_VALUE',
              variableType: 'ENV_VAR',
            },
          ],
        ]);
        expect(wrapper.emitted('close-form')).toBeUndefined();
        expect(wrapper.findComponent(GlDrawer).element.scrollTo).toHaveBeenCalledTimes(1);
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
        findValueField().vm.$emit('input', 'EDITED_VALUE');
        findDescriptionField().vm.$emit('input', 'EDITED_DESCRIPTION');

        await nextTick();

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
        findEnvironmentScopeDropdown().vm.$emit('select-environment', 'staging');
        findConfirmBtn().vm.$emit('click');

        await nextTick();

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
        findEnvironmentScopeDropdown().vm.$emit('search-environment-scope', 'staging');

        await nextTick();

        expect(wrapper.emitted('search-environment-scope')[1]).toEqual(['staging']);
      });
    });
  });
});
