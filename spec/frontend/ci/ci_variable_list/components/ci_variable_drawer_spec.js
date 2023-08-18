import { GlDrawer, GlFormInput, GlFormSelect } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiEnvironmentsDropdown from '~/ci/ci_variable_list/components/ci_environments_dropdown.vue';
import CiVariableDrawer, { i18n } from '~/ci/ci_variable_list/components/ci_variable_drawer.vue';
import {
  ADD_VARIABLE_ACTION,
  EDIT_VARIABLE_ACTION,
  variableOptions,
  projectString,
  variableTypes,
} from '~/ci/ci_variable_list/constants';
import { mockVariablesWithScopes } from '../mocks';

describe('CI Variable Drawer', () => {
  let wrapper;

  const mockProjectVariable = mockVariablesWithScopes(projectString)[0];
  const mockProjectVariableFileType = mockVariablesWithScopes(projectString)[1];
  const mockEnvScope = 'staging';
  const mockEnvironments = ['*', 'dev', 'staging', 'production'];

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

  const findConfirmBtn = () => wrapper.findByTestId('ci-variable-confirm-btn');
  const findDisabledEnvironmentScopeDropdown = () => wrapper.findComponent(GlFormInput);
  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findEnvironmentScopeDropdown = () => wrapper.findComponent(CiEnvironmentsDropdown);
  const findExpandedCheckbox = () => wrapper.findByTestId('ci-variable-expanded-checkbox');
  const findMaskedCheckbox = () => wrapper.findByTestId('ci-variable-masked-checkbox');
  const findProtectedCheckbox = () => wrapper.findByTestId('ci-variable-protected-checkbox');
  const findTitle = () => findDrawer().find('h2');
  const findTypeDropdown = () => wrapper.findComponent(GlFormSelect);

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

    describe('masked flag', () => {
      beforeEach(() => {
        createComponent();
      });

      it('is false by default', () => {
        expect(findMaskedCheckbox().attributes('checked')).toBeUndefined();
      });

      it('inherits value of selected variable when editing', () => {
        createComponent({
          props: {
            selectedVariable: mockProjectVariableFileType,
            mode: EDIT_VARIABLE_ACTION,
          },
        });

        expect(findMaskedCheckbox().attributes('checked')).toBeDefined();
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
        await findExpandedCheckbox().vm.$emit('change');
        await findConfirmBtn().vm.$emit('click');

        const sentRawValue = wrapper.emitted('add-variable')[0][0].raw;
        expect(sentRawValue).toBe(!defaultProps.raw);
      });
    });
  });

  describe('drawer events', () => {
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
        expect(findTitle().text()).toBe(i18n.addVariable);
        expect(findConfirmBtn().text()).toBe(i18n.addVariable);
      });
    });

    describe('when editing a variable', () => {
      beforeEach(() => {
        createComponent({
          props: { mode: EDIT_VARIABLE_ACTION },
          stubs: { GlDrawer },
        });
      });

      it('title and confirm button renders the correct text', () => {
        expect(findTitle().text()).toBe(i18n.editVariable);
        expect(findConfirmBtn().text()).toBe(i18n.editVariable);
      });
    });
  });
});
