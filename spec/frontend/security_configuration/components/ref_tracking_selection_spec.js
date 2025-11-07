import { GlModal, GlSearchBoxByType, GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefTrackingSelection from '~/security_configuration/components/ref_tracking_selection.vue';

describe('RefTrackingSelection component', () => {
  let wrapper;

  const createComponent = ({ isVisible = true } = {}) => {
    wrapper = shallowMountExtended(RefTrackingSelection, {
      propsData: { isVisible },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findCheckboxGroup = () => wrapper.getComponent(GlFormCheckboxGroup);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const getEnteredSearchTerm = () => findSearchBox().props('value');

  const enterSearchTerm = async (searchTerm) => {
    await findSearchBox().vm.$emit('input', searchTerm);
  };

  const selectRefs = async (refIds) => {
    await findCheckboxGroup().vm.$emit('input', refIds);
  };

  const getSelectedRefs = () => {
    const checked = findCheckboxGroup().attributes('checked');
    return checked ? checked.split(',') : [];
  };

  describe('modal visibility', () => {
    it.each([false, true])(
      'renders a "GlModal" with correct visibility when isVisible is set to "%s"',
      (isVisible) => {
        createComponent({ isVisible });

        expect(findModal().props('visible')).toBe(isVisible);
      },
    );
  });

  describe('modal rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('configures primary action button', () => {
      expect(findModal().props('actionPrimary')).toMatchObject({
        text: 'Track ref(s)',
        attributes: {
          variant: 'confirm',
          disabled: true,
        },
      });
    });

    it('configures cancel action button', () => {
      expect(findModal().props('actionCancel')).toEqual({
        text: 'Cancel',
      });
    });

    it('configures modal with correct basic props', () => {
      expect(findModal().props()).toMatchObject({
        actionCancel: { text: 'Cancel' },
        modalId: 'track-ref-selection-modal',
        size: 'lg',
      });
    });

    it('displays all refs initially', () => {
      expect(findAllCheckboxes()).toHaveLength(5);
    });
  });

  describe('selection functionality', () => {
    beforeEach(() => {
      createComponent();
    });

    it('allows refs to be selected', async () => {
      const refsToSelect = ['ref-1', 'ref-2', 'ref-3'];
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);

      await selectRefs(refsToSelect);

      expect(getSelectedRefs()).toEqual(refsToSelect);
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
    });
  });

  describe('user interactions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits "cancel" event, resets the search term and selected refs when modal is hidden', async () => {
      await selectRefs(['ref-1', 'ref-2', 'ref-3']);
      await enterSearchTerm('ref');

      expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
      expect(getEnteredSearchTerm()).toEqual('ref');

      await findModal().vm.$emit('hidden');

      expect(getEnteredSearchTerm()).toEqual('');
      expect(getSelectedRefs()).toEqual([]);
      expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });
  });
});
