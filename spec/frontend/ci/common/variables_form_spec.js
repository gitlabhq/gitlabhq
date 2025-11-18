import { GlFormGroup, GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import {
  shallowMountExtended,
  extendedWrapper,
  mountExtended,
} from 'helpers/vue_test_utils_helper';
import InputsAdoptionBanner from '~/ci/common/pipeline_inputs/inputs_adoption_banner.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';
import VariablesForm from '~/ci/common/variables_form.vue';
import { CI_VARIABLE_TYPE_FILE, CI_VARIABLE_TYPE_ENV_VAR } from '~/ci/pipeline_new/constants';

describe('Pipeline variables form group', () => {
  let wrapper;

  const schedulesCallout = 'pipeline_schedules_inputs_adoption_banner';

  const createComponent = ({ props = {}, mountFn = shallowMountExtended, slots = {} } = {}) => {
    const stubs =
      mountFn === shallowMountExtended ? { GlFormGroup } : { InputsAdoptionBanner: true };

    wrapper = mountFn(VariablesForm, {
      propsData: { ...props, userCalloutsFeatureName: schedulesCallout },
      stubs,
      slots,
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findInputsAdoptionBanner = () => wrapper.findComponent(InputsAdoptionBanner);
  const findVariableRows = () => wrapper.findAllByTestId('ci-variable-row-container');
  const findVariableTypes = () => wrapper.findAllByTestId('pipeline-form-ci-variable-type');
  const findKeyInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-key-field');
  const findValueInputs = () => wrapper.findAllByTestId('pipeline-form-ci-variable-value-field');
  const findHiddenValueInputs = () =>
    wrapper.findAllByTestId('pipeline-form-ci-variable-hidden-value');
  const findVariableSecurityBtn = () => wrapper.findByTestId('variable-security-btn');
  const findRemoveButtonAt = (i) =>
    extendedWrapper(findVariableRows().at(i)).findByTestId('remove-ci-variable-button');
  const findRemoveButtonDesktopAt = (i) =>
    extendedWrapper(findVariableRows().at(i)).findByTestId('remove-ci-variable-button-desktop');
  const findMarkdown = () => wrapper.findComponent(Markdown);
  const findVariableValuesListbox = () =>
    wrapper.findAllByTestId('pipeline-form-ci-variable-value-dropdown');

  const addVariableToForm = async () => {
    const input = findKeyInputs().at(0);
    input.setValue('test_var');
    input.trigger('change');
    await nextTick();
  };

  describe('Pipeline inputs banner', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays the inputs adoption banner with the provided featureName', () => {
      expect(findInputsAdoptionBanner().props('featureName')).toBe(schedulesCallout);
    });
  });

  describe('loading state', () => {
    it('shows loading icon when isLoading is true', () => {
      createComponent({ props: { isLoading: true } });

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findVariableRows().exists()).toBe(false);
    });

    it('removes loading icon when isLoading is false', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findVariableRows().exists()).toBe(true);
    });
  });

  describe('Initial state and watchers', () => {
    beforeEach(() => {
      createComponent();
    });
    it('creates an empty variable row when initialVariables is set', () => {
      expect(findVariableRows()).toHaveLength(1);
      expect(findKeyInputs().at(0).props('value')).toBe('');
      expect(findValueInputs().at(0).props('value')).toBe('');
    });

    it('defaults to ENV_VAR variable type', () => {
      expect(findVariableTypes().at(0).props('selected')).toBe(CI_VARIABLE_TYPE_ENV_VAR);
    });

    it('does not show variable security button when not editing', () => {
      expect(findVariableSecurityBtn().exists()).toBe(false);
    });

    it('properly reacts to initialVariables changes', async () => {
      const newVariables = [
        { key: 'NEW_VAR', value: 'new-value', variableType: CI_VARIABLE_TYPE_FILE },
      ];
      await wrapper.setProps({ initialVariables: newVariables });

      expect(findVariableRows()).toHaveLength(2);

      expect(findKeyInputs().at(0).props('value')).toBe('NEW_VAR');
      expect(findValueInputs().at(0).props('value')).toBe('new-value');
      expect(findKeyInputs().at(1).props('value')).toBe('');
    });
  });

  describe('Variable operations', () => {
    beforeEach(() => {
      createComponent({ mountFn: mountExtended });
    });

    it('changes variable type', async () => {
      await findKeyInputs().at(0).setValue('test_key');

      findVariableTypes().at(0).vm.$emit('select', CI_VARIABLE_TYPE_FILE);
      await nextTick();
      expect(findVariableTypes().at(0).props('selected')).toBe(CI_VARIABLE_TYPE_FILE);
    });

    it('creates blank variable on input change event', async () => {
      expect(findVariableRows()).toHaveLength(1);
      await addVariableToForm();

      expect(findVariableRows()).toHaveLength(2);
      expect(findKeyInputs().at(1).props('value')).toBe('');
      expect(findValueInputs().at(1).props('value')).toBe('');
    });

    it('does not display remove icon for last row', async () => {
      await addVariableToForm();

      expect(findRemoveButtonAt(0).exists()).toBe(true);
      expect(findRemoveButtonDesktopAt(0).props('disabled')).toBe(false);
      expect(findRemoveButtonDesktopAt(0).classes('gl-invisible')).toBe(false);

      expect(findRemoveButtonAt(1).exists()).toBe(false);
      expect(findRemoveButtonDesktopAt(1).props('disabled')).toBe(true);
      expect(findRemoveButtonDesktopAt(1).classes('gl-invisible')).toBe(true);
    });

    it('removes ci variable row on remove icon button click', async () => {
      await addVariableToForm();
      expect(findVariableRows()).toHaveLength(2);

      findRemoveButtonAt(0).trigger('click');
      await nextTick();
      expect(findVariableRows()).toHaveLength(1);
    });

    it('emits update-variables event when variable is added', async () => {
      expect(wrapper.emitted('update-variables')).toHaveLength(1);
      await addVariableToForm();

      expect(wrapper.emitted('update-variables').at(-1)[0]).toMatchObject([
        { destroy: false, empty: true, key: 'test_var', value: '', variableType: 'ENV_VAR' },
        { destroy: false, empty: true, key: '', value: '', variableType: 'ENV_VAR' },
      ]);
    });

    it('emits update-variables event when variable is removed', async () => {
      expect(wrapper.emitted('update-variables')).toHaveLength(1);
      await addVariableToForm();

      expect(wrapper.emitted('update-variables').at(-1)[0]).toMatchObject([
        { destroy: false, empty: true, key: 'test_var', value: '', variableType: 'ENV_VAR' },
        { destroy: false, empty: true, key: '', value: '', variableType: 'ENV_VAR' },
      ]);
      findRemoveButtonAt(0).trigger('click');
      await nextTick();

      // Check that the variable was marked as destroyed but not actually removed from the array
      expect(wrapper.emitted('update-variables').at(-1)[0]).toMatchObject([
        { destroy: true, empty: true, key: 'test_var', value: '', variableType: 'ENV_VAR' },
        { destroy: false, empty: true, key: '', value: '', variableType: 'ENV_VAR' },
      ]);
    });

    it('marks a variable as non-empty when its value changes', async () => {
      await addVariableToForm();

      expect(wrapper.emitted('update-variables').at(-1)[0]).toMatchObject([
        { destroy: false, empty: true, key: 'test_var', value: '', variableType: 'ENV_VAR' },
        { destroy: false, empty: true, key: '', value: '', variableType: 'ENV_VAR' },
      ]);

      const valueInput = findValueInputs().at(0);
      valueInput.setValue('some value');
      valueInput.trigger('change');
      await nextTick();

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

  describe('destroy variable', () => {
    beforeEach(() => {
      createComponent({
        mountFn: mountExtended,
        props: {
          initialVariables: [
            { key: 'VAR1', value: 'val1', variableType: CI_VARIABLE_TYPE_ENV_VAR },
            { key: 'VAR2', value: 'val2', variableType: CI_VARIABLE_TYPE_ENV_VAR },
          ],
        },
      });
    });

    it('handles multiple destroy operations', async () => {
      findRemoveButtonAt(1).trigger('click');
      await nextTick();
      findRemoveButtonAt(0).trigger('click');
      await nextTick();

      const emitted = wrapper.emitted('update-variables').at(-1)[0];
      expect(emitted.filter((v) => v.destroy)).toHaveLength(2);
    });

    it('prevents destroying the last empty row', () => {
      const lastRowIndex = findVariableRows().length - 1;
      expect(findVariableRows().at(lastRowIndex).exists()).toBe(true);
      expect(findRemoveButtonAt(lastRowIndex).exists()).toBe(false);
    });

    it('emits all variables including destroyed ones', async () => {
      findRemoveButtonAt(0).trigger('click');
      await nextTick();

      const emitted = wrapper.emitted('update-variables').at(-1)[0];
      const destroyedVar = emitted.find((v) => v.key === 'VAR1');

      expect(destroyedVar).toBeDefined();
      expect(destroyedVar.destroy).toBe(true);
    });

    it('hides destroyed variables from visible list', async () => {
      expect(findVariableRows()).toHaveLength(3); // 2 + empty row

      findRemoveButtonAt(0).trigger('click');
      await nextTick();

      expect(findVariableRows()).toHaveLength(2); // 1 + empty row
    });
  });

  describe('variable removal with responsive design', () => {
    beforeEach(async () => {
      await createComponent({
        props: {
          initialVariables: [
            { key: 'VAR1', value: 'val1', variableType: CI_VARIABLE_TYPE_ENV_VAR },
          ],
        },
      });
    });

    it('uses secondary button category on mobile', () => {
      expect(findRemoveButtonAt(0).exists()).toBe(true);

      expect(findRemoveButtonAt(0).props('size')).toBe('medium');
      expect(findRemoveButtonAt(0).props('icon')).toBe('remove');
      expect(findRemoveButtonAt(0).props('disabled')).toBe(false);
      expect(findRemoveButtonAt(0).props('category')).toBe('secondary');

      expect(findRemoveButtonAt(0).text()).toBe('Remove variable');
    });

    it('uses tertiary button category on desktop', () => {
      expect(findRemoveButtonDesktopAt(0).exists()).toBe(true);

      expect(findRemoveButtonDesktopAt(0).props('size')).toBe('medium');
      expect(findRemoveButtonDesktopAt(0).props('icon')).toBe('remove');
      expect(findRemoveButtonDesktopAt(0).props('disabled')).toBe(false);
      expect(findRemoveButtonDesktopAt(0).props('category')).toBe('tertiary');

      expect(findRemoveButtonDesktopAt(0).attributes('aria-label')).toBe('Remove variable');
    });
  });

  describe('Editing mode', () => {
    const mockVariables = [
      {
        id: '1',
        key: 'TEST_VAR_1',
        value: 'test-value-1',
        variableType: CI_VARIABLE_TYPE_FILE,
        destroy: false,
      },
      {
        id: '2',
        key: 'TEST_VAR_2',
        value: 'test-value-2',
        variableType: CI_VARIABLE_TYPE_ENV_VAR,
        destroy: false,
      },
    ];

    beforeEach(() => {
      createComponent({
        props: {
          initialVariables: mockVariables,
          editing: true,
        },
      });
    });

    it('displays existing variables', () => {
      expect(findVariableRows()).toHaveLength(3); // 2 existing + 1 empty
      expect(findKeyInputs().at(0).props('value')).toBe(mockVariables[0].key);
      expect(findKeyInputs().at(1).props('value')).toBe(mockVariables[1].key);
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
      expect(findValueInputs().at(0).props('value')).toBe(mockVariables[0].value);
      expect(findValueInputs().at(1).props('value')).toBe(mockVariables[1].value);
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

  describe('Variable descriptions', () => {
    it('renders markdown when variable has description', () => {
      const variablesWithDescription = [
        {
          key: 'VAR1',
          value: 'value1',
          variableType: CI_VARIABLE_TYPE_ENV_VAR,
          description: 'Variable with **Markdown** _description_',
        },
      ];

      createComponent({
        props: {
          initialVariables: variablesWithDescription,
        },
      });

      expect(findMarkdown().exists()).toBe(true);
      expect(findMarkdown().props('markdown')).toBe('Variable with **Markdown** _description_');
    });

    it('does not render markdown when variable has no description', () => {
      const variablesWithoutDescription = [
        {
          key: 'VAR1',
          value: 'value1',
          variableType: CI_VARIABLE_TYPE_ENV_VAR,
        },
      ];

      createComponent({
        props: {
          initialVariables: variablesWithoutDescription,
        },
      });

      expect(findMarkdown().exists()).toBe(false);
    });
  });

  describe('Value options dropdown', () => {
    it('shows dropdown when variable has multiple value options', () => {
      const variablesWithOptions = [
        {
          key: 'ENV',
          value: 'prod',
          variableType: CI_VARIABLE_TYPE_ENV_VAR,
          valueOptions: ['dev', 'staging', 'prod'],
        },
      ];

      createComponent({
        props: {
          initialVariables: variablesWithOptions,
        },
        mountFn: mountExtended,
      });

      expect(findVariableValuesListbox().exists()).toBe(true);
    });

    it('removes duplicate options from the dropdown', () => {
      const variablesWithDuplicates = [
        {
          key: 'ENV',
          value: 'option1',
          variableType: CI_VARIABLE_TYPE_ENV_VAR,
          valueOptions: ['option1', 'option2', 'option1', 'option3', 'option2'],
        },
      ];

      createComponent({
        props: {
          initialVariables: variablesWithDuplicates,
        },
        mountFn: mountExtended,
      });

      expect(findVariableValuesListbox().at(0).props('items')).toEqual([
        { text: 'option1', value: 'option1' },
        { text: 'option2', value: 'option2' },
        { text: 'option3', value: 'option3' },
      ]);
    });

    it('shows textarea when variable has less than 2 value options', () => {
      const variablesWithOneOption = [
        {
          key: 'VAR',
          value: 'only-option',
          variableType: CI_VARIABLE_TYPE_ENV_VAR,
          valueOptions: ['only-option'],
        },
      ];

      createComponent({
        props: {
          initialVariables: variablesWithOneOption,
        },
        mountFn: mountExtended,
      });

      expect(findVariableValuesListbox().exists()).toBe(false);
      expect(findValueInputs()).toHaveLength(2); // The variable + empty row
    });
  });

  describe('description slot', () => {
    const descriptionContent = 'Custom description text';
    it('renders description slot content when provided', () => {
      createComponent({
        slots: {
          description: descriptionContent,
        },
      });

      expect(wrapper.text()).toContain(descriptionContent);
    });

    it('does not render description section when slot is not provided', () => {
      createComponent();

      expect(wrapper.text()).not.toContain(descriptionContent);
    });
  });
});
