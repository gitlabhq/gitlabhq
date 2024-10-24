import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GkeNodePoolGroup from '~/ci/runner/components/registration/gke_node_pool_group.vue';

describe('GKE Node Pool Group', () => {
  let wrapper;

  const findNodePoolNameInput = () => wrapper.findByTestId('node-pool-name-input');
  const findNodePoolCountInput = () => wrapper.findByTestId('node-count-input');
  const findNodePoolImageTypeInput = () => wrapper.findByTestId('image-type-input');
  const findNodePoolMachineTypeInput = () => wrapper.findByTestId('machine-type-input');

  // Node pool labels
  const findNodePoolLabelRows = () => wrapper.findAllByTestId('node-pool-label-row-container');
  const findKeyInputs = () => wrapper.findAllByTestId('node-pool-label-key-field');
  const findValueInputs = () => wrapper.findAllByTestId('node-pool-label-value-field');
  const findRemoveIcons = () => wrapper.findAllByTestId('remove-node-pool-label');

  const findRemoveNodePoolButton = () => wrapper.findByTestId('remove-node-pool-button');

  const fillInTextField = (formGroup, value) => {
    const input = formGroup.find('input');
    input.element.value = value;
    return input.trigger('change');
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(GkeNodePoolGroup, {
      propsData: {
        ...props,
      },
    });
  };

  it('displays form inputs', () => {
    createComponent();

    expect(findNodePoolNameInput().exists()).toBe(true);
    expect(findNodePoolCountInput().exists()).toBe(true);
    expect(findNodePoolImageTypeInput().exists()).toBe(true);
    expect(findNodePoolMachineTypeInput().exists()).toBe(true);
  });

  it('emits a remove-node-pool event when the remove button is available', async () => {
    createComponent({
      props: {
        uniqueIdentifier: 1,
        showRemoveButton: true,
      },
    });

    await findRemoveNodePoolButton().vm.$emit('click');

    expect(wrapper.emitted('remove-node-pool')).toEqual([[{ uniqueIdentifier: 1 }]]);
  });

  it('shows the remove node pool button when the showRemoveButton prop is set', () => {
    createComponent({
      props: {
        showRemoveButton: true,
      },
    });

    expect(findRemoveNodePoolButton().exists()).toBe(true);
    expect(findRemoveNodePoolButton().classes('btn-danger')).toBe(true);
  });

  describe('Field validations', () => {
    const expectValidation = (fieldGroup, { ariaInvalid, feedback }) => {
      expect(fieldGroup.attributes('aria-invalid')).toBe(ariaInvalid);
      expect(fieldGroup.find('input').attributes('aria-invalid')).toBe(ariaInvalid);
      expect(fieldGroup.text()).toContain(feedback);
    };

    beforeEach(() => {
      createComponent();
    });

    describe('node pool name validates', () => {
      it.each`
        case                            | input               | ariaInvalid  | feedback
        ${'correct'}                    | ${'node-pool-1'}    | ${undefined} | ${''}
        ${'correct'}                    | ${'node-pool'}      | ${undefined} | ${''}
        ${'invalid (uppercase letter)'} | ${'NODE-pool-1'}    | ${'true'}    | ${'Node pool name'}
        ${'invalid (number)'}           | ${'22-node-pool-2'} | ${'true'}    | ${'Node pool name'}
        ${'invalid (ends in dash)'}     | ${'node-pool-1-'}   | ${'true'}    | ${'Node pool name'}
        ${'invalid (contains space)'}   | ${'node-pool '}     | ${'true'}    | ${'Node pool name'}
        ${'invalid (missing)'}          | ${''}               | ${'true'}    | ${'Node pool name'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findNodePoolNameInput(), input);

        expectValidation(findNodePoolNameInput(), { ariaInvalid, feedback });
      });
    });

    describe('node pool count validates', () => {
      it.each`
        case                        | input    | ariaInvalid  | feedback
        ${'correct'}                | ${'10'}  | ${undefined} | ${''}
        ${'correct'}                | ${'100'} | ${undefined} | ${''}
        ${'correct'}                | ${'200'} | ${undefined} | ${''}
        ${'invalid (with letters)'} | ${'ten'} | ${'true'}    | ${'Node count'}
        ${'invalid (with dash)'}    | ${'--'}  | ${'true'}    | ${'Node count'}
        ${'invalid (ends in dash)'} | ${'10-'} | ${'true'}    | ${'Node count'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findNodePoolCountInput(), input);

        expectValidation(findNodePoolCountInput(), { ariaInvalid, feedback });
      });
    });

    describe('machine type validates', () => {
      it.each`
        case                            | input                   | ariaInvalid  | feedback
        ${'correct'}                    | ${'n2-standard-2'}      | ${undefined} | ${''}
        ${'correct'}                    | ${'t2d-standard-1'}     | ${undefined} | ${''}
        ${'correct'}                    | ${'t2a-standard-48'}    | ${undefined} | ${''}
        ${'correct'}                    | ${'t2d-standard-1'}     | ${undefined} | ${''}
        ${'correct'}                    | ${'c3-standard-4-lssd'} | ${undefined} | ${''}
        ${'correct'}                    | ${'f1-micro'}           | ${undefined} | ${''}
        ${'correct'}                    | ${'f1'}                 | ${undefined} | ${''}
        ${'invalid (uppercase letter)'} | ${'N2-standard-2'}      | ${'true'}    | ${'Machine type must have'}
        ${'invalid (number)'}           | ${'22-standard-2'}      | ${'true'}    | ${'Machine type must have'}
        ${'invalid (ends in dash)'}     | ${'22-standard-2-'}     | ${'true'}    | ${'Machine type must have'}
        ${'invalid (contains space)'}   | ${'n2-standard-2 '}     | ${'true'}    | ${'Machine type must have'}
        ${'invalid (missing)'}          | ${''}                   | ${'true'}    | ${'Machine type is required'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findNodePoolMachineTypeInput(), input);

        expectValidation(findNodePoolMachineTypeInput(), { ariaInvalid, feedback });
      });
    });

    describe('image type validates', () => {
      it.each`
        case                            | input                  | ariaInvalid  | feedback
        ${'correct'}                    | ${'ubuntu'}            | ${undefined} | ${''}
        ${'correct'}                    | ${'ubuntu_ltsc'}       | ${undefined} | ${''}
        ${'correct'}                    | ${'windows'}           | ${undefined} | ${''}
        ${'correct'}                    | ${'windows_ltsc'}      | ${undefined} | ${''}
        ${'correct'}                    | ${'ubuntu_containerd'} | ${undefined} | ${''}
        ${'correct'}                    | ${'cos_containerd'}    | ${undefined} | ${''}
        ${'correct'}                    | ${'windows_sac'}       | ${undefined} | ${''}
        ${'invalid (uppercase letter)'} | ${'UBUNTU'}            | ${'true'}    | ${'Image Type'}
        ${'invalid (missing suffix)'}   | ${'ubuntu_'}           | ${'true'}    | ${'Image Type'}
        ${'invalid (contains numbers)'} | ${'ubuntu12937'}       | ${'true'}    | ${'Image Type'}
        ${'invalid (contains space)'}   | ${'ubuntu '}           | ${'true'}    | ${'Image Type'}
        ${'invalid (missing)'}          | ${''}                  | ${'true'}    | ${'Image Type'}
      `('"$input" as $case', async ({ input, ariaInvalid, feedback }) => {
        await fillInTextField(findNodePoolImageTypeInput(), input);

        expectValidation(findNodePoolImageTypeInput(), { ariaInvalid, feedback });
      });
    });
  });

  describe('Node pool labels', () => {
    beforeEach(async () => {
      createComponent();

      const input = findKeyInputs().at(0);

      input.vm.$emit('input', 'env');
      input.vm.$emit('change');

      await nextTick();
    });

    it('creates blank node pool label on input change event', () => {
      expect(findNodePoolLabelRows()).toHaveLength(2);
      expect(findKeyInputs().at(1).exists()).toBe(true);
      expect(findValueInputs().at(1).exists()).toBe(true);
    });

    it('displays the remove icon when more than one set of labels is on display', () => {
      expect(findRemoveIcons().at(0).props('category')).toBe('tertiary');
      expect(findRemoveIcons().at(0).props('variant')).toBe('default');
      expect(findRemoveIcons().at(0).findComponent(GlIcon).props('name')).toBe('remove');
    });

    it('does not display the remove icon for the last row', () => {
      expect(findRemoveIcons()).toHaveLength(1);
    });

    it('removes a node pool label', async () => {
      expect(findNodePoolLabelRows()).toHaveLength(2);

      findRemoveIcons().at(0).vm.$emit('click');

      await nextTick();

      expect(findNodePoolLabelRows()).toHaveLength(1);
    });
  });
});
