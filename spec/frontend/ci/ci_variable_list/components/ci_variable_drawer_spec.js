import { GlDrawer, GlFormSelect } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CiVariableDrawer from '~/ci/ci_variable_list/components/ci_variable_drawer.vue';
import {
  ADD_VARIABLE_ACTION,
  variableOptions,
  variableTypes,
} from '~/ci/ci_variable_list/constants';

describe('CI Variable Drawer', () => {
  let wrapper;

  const defaultProps = {
    areEnvironmentsLoading: false,
    hasEnvScopeQuery: true,
    mode: ADD_VARIABLE_ACTION,
  };

  const createComponent = ({ mountFn = shallowMountExtended, props = {} } = {}) => {
    wrapper = mountFn(CiVariableDrawer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        environmentScopeLink: '/help/environments',
      },
    });
  };

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findTypeDropdown = () => wrapper.findComponent(GlFormSelect);

  describe('validations', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    describe('type dropdown', () => {
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
    });
  });

  describe('drawer events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits `close-form` when closing the drawer', async () => {
      expect(wrapper.emitted('close-form')).toBeUndefined();

      await findDrawer().vm.$emit('close');

      expect(wrapper.emitted('close-form')).toHaveLength(1);
    });
  });
});
