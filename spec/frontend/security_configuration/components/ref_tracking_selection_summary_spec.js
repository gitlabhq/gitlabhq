import { GlButton, GlCollapse, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import RefTrackingSelectionSummary from '~/security_configuration/components/ref_tracking_selection_summary.vue';

const mockRefs = [
  {
    id: 'branch-main',
    name: 'main',
    refType: 'BRANCH',
  },
  {
    id: 'branch-feature',
    name: 'feature-branch',
    refType: 'BRANCH',
  },
  {
    id: 'tag-v1.0.0',
    name: 'v1.0.0',
    refType: 'TAG',
  },
];

describe('RefTrackingSelectionSummary component', () => {
  let wrapper;

  const createComponent = ({ selectedRefs = [], availableSpots = 10 } = {}) => {
    wrapper = shallowMountExtended(RefTrackingSelectionSummary, {
      propsData: {
        selectedRefs,
        availableSpots,
      },
    });
  };

  const findCounterText = () => wrapper.text();
  const findMaxLimitWarning = () => wrapper.findByTestId('max-limit-warning');
  const findMaxLimitWarningContainer = () => wrapper.findByTestId('max-limit-warning-container');
  const findChipsContainer = () => wrapper.findByTestId('selected-refs-chips');
  const findAllChips = () => wrapper.findAllByTestId('selected-ref-chip');
  const findChipIcon = (chipWrapper) => chipWrapper.findComponent(GlIcon);
  const findChipRemoveButton = (chipWrapper) => chipWrapper.findComponent(GlButton);

  const isExpanded = (container) => {
    return container.findComponent(GlCollapse).props('visible');
  };

  describe('counter display', () => {
    it.each`
      description          | selectedRefs                  | availableSpots | expectedText
      ${'no selections'}   | ${[]}                         | ${10}          | ${'0 refs selected of 10 spots available'}
      ${'some selections'} | ${[mockRefs[0], mockRefs[1]]} | ${5}           | ${'2 refs selected of 5 spots available'}
      ${'at the limit'}    | ${[mockRefs[0], mockRefs[1]]} | ${0}           | ${'2 refs selected of 0 spots available'}
    `('displays $description', ({ selectedRefs, availableSpots, expectedText }) => {
      createComponent({ selectedRefs, availableSpots });

      expect(findCounterText()).toContain(expectedText);
    });
  });

  describe('max limit warning', () => {
    it('hides the warning when the limit is not reached', () => {
      createComponent({ availableSpots: 10 });

      expect(isExpanded(findMaxLimitWarningContainer())).toBe(false);
    });

    it('shows the warning when the max limit is reached', () => {
      createComponent({ availableSpots: 0 });

      expect(isExpanded(findMaxLimitWarningContainer())).toBe(true);
      expect(findMaxLimitWarning().text()).toBe(
        'You can remove tracked refs in the Configuration page.',
      );
    });
  });

  describe('chips display', () => {
    it('hides the chips container when no refs are selected', () => {
      createComponent({ selectedRefs: [] });

      expect(isExpanded(findChipsContainer())).toBe(false);
    });

    it('shows the chips container when refs are selected', () => {
      createComponent({ selectedRefs: [mockRefs[0]] });

      expect(isExpanded(findChipsContainer())).toBe(true);
    });

    it('displays the correct number of chips', () => {
      createComponent({ selectedRefs: [mockRefs[0], mockRefs[1], mockRefs[2]] });

      expect(findAllChips()).toHaveLength(3);
    });

    it('displays the correct ref name in the chip', () => {
      createComponent({ selectedRefs: [mockRefs[0]] });

      expect(findAllChips().at(0).text()).toContain('main');
    });
  });

  describe('ref icons', () => {
    it.each`
      description                            | selectedRefs                  | expectedIconNames
      ${'branch icon for branch refs'}       | ${[mockRefs[0]]}              | ${['branch']}
      ${'tag icon for tag refs'}             | ${[mockRefs[2]]}              | ${['tag']}
      ${'correct icons for mixed ref types'} | ${[mockRefs[0], mockRefs[2]]} | ${['branch', 'tag']}
    `('displays $description', ({ selectedRefs, expectedIconNames }) => {
      createComponent({ selectedRefs });

      const chips = findAllChips();

      expectedIconNames.forEach((iconName, index) => {
        const icon = findChipIcon(chips.at(index));
        expect(icon.props('name')).toBe(iconName);
        expect(icon.props('size')).toBe(12);
      });
    });
  });

  describe('chip interactions', () => {
    beforeEach(() => {
      createComponent({ selectedRefs: [mockRefs[0], mockRefs[1]] });
    });

    it('renders remove button with correct props', () => {
      const chip = findAllChips().at(0);
      const button = findChipRemoveButton(chip);

      expect(button.props()).toMatchObject({
        category: 'tertiary',
        size: 'small',
        icon: 'close',
      });
    });

    it('sets correct aria-label on remove button', () => {
      const chip = findAllChips().at(0);
      const button = findChipRemoveButton(chip);

      expect(button.attributes('aria-label')).toBe('Remove main');
    });

    it('emits remove event with correct ref when the remove button is clicked', () => {
      const chip = findAllChips().at(0);
      const button = findChipRemoveButton(chip);

      button.vm.$emit('click');

      expect(wrapper.emitted('remove')).toHaveLength(1);
      expect(wrapper.emitted('remove')[0]).toEqual([mockRefs[0]]);
    });
  });
});
