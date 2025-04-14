import { nextTick } from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import InputsAdoptionBanner from '~/ci/common/pipeline_inputs/inputs_adoption_banner.vue';
import PipelineVariablesFormGroup from '~/ci/pipeline_schedules/components/pipeline_variables_form_group.vue';
import { VARIABLE_TYPE, FILE_TYPE } from '~/ci/pipeline_schedules/constants';

describe('Pipeline variables form group', () => {
  let wrapper;

  const createComponent = (
    mountFn = shallowMountExtended,
    props = {
      initialVariables: [],
      editing: false,
    },
    ciInputsForPipelines = false,
  ) => {
    wrapper = mountFn(PipelineVariablesFormGroup, {
      propsData: props,
      provide: {
        glFeatures: {
          ciInputsForPipelines,
        },
      },
    });
  };

  const findInputsAdoptionBanner = () => wrapper.findComponent(InputsAdoptionBanner);
  const findVariableRows = () => wrapper.findAllByTestId('ci-variable-row');
  const findVariableTypes = () => wrapper.findAllByTestId('pipeline-form-ci-variable-type');
  const findKeyInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-key');
  const findValueInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-value');
  const findHiddenValueInputs = () =>
    wrapper.findAllByTestId('pipeline-form-ci-variable-hidden-value');
  const findVariableSecurityBtn = () => wrapper.findByTestId('variable-security-btn');
  const findRemoveIcons = () => wrapper.findAllByTestId('remove-ci-variable-row');

  const addVariableToForm = () => {
    const input = findKeyInputs().at(0);
    input.setValue('test_var');
    input.trigger('change');
  };

  describe('Feature flag', () => {
    describe('when the ciInputsForPipelines flag is disabled', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not display the inputs adoption banner', () => {
        expect(findInputsAdoptionBanner().exists()).toBe(false);
      });
    });

    describe('when the ciInputsForPipelines flag is enabled', () => {
      beforeEach(() => {
        createComponent(undefined, undefined, true);
      });

      it('displays the inputs adoption banner', () => {
        expect(findInputsAdoptionBanner().exists()).toBe(true);
        expect(findInputsAdoptionBanner().props('featureName')).toBe(
          'pipeline_schedules_inputs_adoption_banner',
        );
      });
    });
  });

  describe('Initial state and watchers', () => {
    it('creates an empty variable row when initialVariables is set', () => {
      createComponent();

      expect(findVariableRows()).toHaveLength(1);
      expect(findKeyInputs().at(0).props('value')).toBe('');
      expect(findValueInputs().at(0).props('value')).toBe('');
    });

    it('defaults to ENV_VAR variable type', () => {
      createComponent();

      expect(findVariableTypes().at(0).props('selected')).toBe(VARIABLE_TYPE);
    });

    it('does not show variable security button when not editing', () => {
      createComponent();

      expect(findVariableSecurityBtn().exists()).toBe(false);
    });

    it('properly reacts to initialVariables changes', async () => {
      createComponent(mountExtended);

      const newVariables = [{ key: 'NEW_VAR', value: 'new-value', variableType: VARIABLE_TYPE }];
      await wrapper.setProps({ initialVariables: newVariables });

      expect(findVariableRows()).toHaveLength(2);

      expect(findKeyInputs().at(0).element.value).toBe('NEW_VAR');
      expect(findValueInputs().at(0).element.value).toBe('new-value');
      expect(findKeyInputs().at(1).element.value).toBe('');
    });
  });

  describe('Variable operations', () => {
    beforeEach(() => {
      createComponent(mountExtended);
    });

    it('changes variable type', async () => {
      const input = findKeyInputs().at(0);
      await input.setValue('test_key');

      findVariableTypes().at(0).vm.$emit('select', FILE_TYPE);
      await nextTick();
      expect(findVariableTypes().at(0).props('selected')).toBe(FILE_TYPE);
    });

    it('creates blank variable on input change event', async () => {
      expect(findVariableRows()).toHaveLength(1);
      addVariableToForm();
      await nextTick();

      expect(findVariableRows()).toHaveLength(2);
      expect(findKeyInputs().at(1).element.value).toBe('');
      expect(findValueInputs().at(1).element.value).toBe('');
    });

    it('does not display remove icon for last row', async () => {
      addVariableToForm();
      await nextTick();

      expect(findRemoveIcons()).toHaveLength(1);
    });

    it('removes ci variable row on remove icon button click', async () => {
      addVariableToForm();
      await nextTick();
      expect(findVariableRows()).toHaveLength(2);

      findRemoveIcons().at(0).trigger('click');
      await nextTick();
      expect(findVariableRows()).toHaveLength(1);
    });

    it('emits update-variables event when variable is added', async () => {
      expect(wrapper.emitted('update-variables')).toHaveLength(1);

      addVariableToForm();
      await nextTick();

      expect(wrapper.emitted('update-variables').at(-1)[0]).toMatchObject([
        { destroy: false, empty: true, key: 'test_var', value: '', variableType: 'ENV_VAR' },
        { destroy: false, empty: true, key: '', value: '', variableType: 'ENV_VAR' },
      ]);
      expect(wrapper.emitted('update-variables')).toHaveLength(2);
    });

    it('emits update-variables event when variable is removed', async () => {
      expect(wrapper.emitted('update-variables')).toHaveLength(1);
      addVariableToForm();
      await nextTick();

      expect(wrapper.emitted('update-variables')).toHaveLength(2);
      findRemoveIcons().at(0).trigger('click');
      await nextTick();

      expect(wrapper.emitted('update-variables')).toHaveLength(3);

      // Check that the variable was marked as destroyed but not actually removed from the array
      expect(wrapper.emitted('update-variables').at(-1)[0]).toMatchObject([
        { destroy: true, empty: true, key: 'test_var', value: '', variableType: 'ENV_VAR' },
        { destroy: false, empty: true, key: '', value: '', variableType: 'ENV_VAR' },
      ]);
    });

    it('marks a variable as non-empty when its value changes', async () => {
      addVariableToForm();
      await nextTick();

      expect(wrapper.emitted('update-variables').at(-1)[0]).toMatchObject([
        { destroy: false, empty: true, key: 'test_var', value: '', variableType: 'ENV_VAR' },
        { destroy: false, empty: true, key: '', value: '', variableType: 'ENV_VAR' },
      ]);

      const valueInput = findValueInputs().at(0);
      await valueInput.setValue('some value');
      await valueInput.trigger('change');

      // Check that the variable is no longer marked as empty
      expect(wrapper.emitted('update-variables').at(-1)[0]).toMatchObject([
        {
          destroy: false,
          empty: false,
          key: 'test_var',
          value: 'some value',
          variableType: 'ENV_VAR',
        },
        { destroy: false, empty: true, key: '', value: '', variableType: 'ENV_VAR' },
      ]);
    });
  });

  describe('Editing mode', () => {
    const mockVariables = [
      {
        id: '1',
        key: 'TEST_VAR_1',
        value: 'test-value-1',
        variableType: VARIABLE_TYPE,
        destroy: false,
      },
      {
        id: '2',
        key: 'TEST_VAR_2',
        value: 'test-value-2',
        variableType: FILE_TYPE,
        destroy: false,
      },
    ];

    beforeEach(() => {
      createComponent(mountExtended, {
        initialVariables: mockVariables,
        editing: true,
      });
    });

    it('displays existing variables', () => {
      expect(findVariableRows()).toHaveLength(3); // 2 existing + 1 empty
      expect(findKeyInputs().at(0).element.value).toBe(mockVariables[0].key);
      expect(findKeyInputs().at(1).element.value).toBe(mockVariables[1].key);
    });

    it('shows variable security button when editing with variables', () => {
      expect(findVariableSecurityBtn().exists()).toBe(true);
    });

    it('hides variable values by default when editing', () => {
      expect(findHiddenValueInputs()).toHaveLength(2);
      expect(findValueInputs()).toHaveLength(1);
    });

    it('toggles variable value visibility when security button is clicked', async () => {
      // Initially values are hidden
      expect(findHiddenValueInputs()).toHaveLength(2);
      expect(findValueInputs()).toHaveLength(1);
      expect(findVariableSecurityBtn().text()).toBe('Reveal values');

      // Click the button to show values
      findVariableSecurityBtn().vm.$emit('click');
      await nextTick();

      // Now values should be visible
      expect(findHiddenValueInputs()).toHaveLength(0);
      expect(findValueInputs()).toHaveLength(3);
      expect(findValueInputs().at(0).element.value).toBe(mockVariables[0].value);
      expect(findValueInputs().at(1).element.value).toBe(mockVariables[1].value);
      expect(findVariableSecurityBtn().text()).toBe('Hide values');

      // Click again to hide values
      findVariableSecurityBtn().vm.$emit('click');
      await nextTick();

      // Values should be hidden again
      expect(findHiddenValueInputs()).toHaveLength(2);
      expect(findValueInputs()).toHaveLength(1);
      expect(findVariableSecurityBtn().text()).toBe('Reveal values');
    });
  });
});
