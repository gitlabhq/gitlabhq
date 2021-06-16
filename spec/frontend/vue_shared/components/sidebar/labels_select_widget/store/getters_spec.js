import * as getters from '~/vue_shared/components/sidebar/labels_select_widget/store/getters';

describe('LabelsSelect Getters', () => {
  describe('dropdownButtonText', () => {
    it.each`
      labelType    | dropdownButtonText | expected
      ${'default'} | ${''}              | ${'Label'}
      ${'custom'}  | ${'Custom label'}  | ${'Custom label'}
    `(
      'returns $labelType text when state.labels has no selected labels',
      ({ dropdownButtonText, expected }) => {
        const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];
        const selectedLabels = [];
        const state = { labels, selectedLabels, dropdownButtonText };

        expect(getters.dropdownButtonText(state, {})).toBe(expected);
      },
    );

    it('returns label title when state.labels has only 1 label', () => {
      const labels = [{ id: 1, title: 'Foobar', set: true }];

      expect(getters.dropdownButtonText({ labels }, { isDropdownVariantSidebar: true })).toBe(
        'Foobar',
      );
    });

    it('returns first label title and remaining labels count when state.labels has more than 1 label', () => {
      const labels = [
        { id: 1, title: 'Foo', set: true },
        { id: 2, title: 'Bar', set: true },
      ];

      expect(getters.dropdownButtonText({ labels }, { isDropdownVariantSidebar: true })).toBe(
        'Foo +1 more',
      );
    });
  });

  describe('selectedLabelsList', () => {
    it('returns array of IDs of all labels within `state.selectedLabels`', () => {
      const selectedLabels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];

      expect(getters.selectedLabelsList({ selectedLabels })).toEqual([1, 2, 3, 4]);
    });
  });

  describe('isDropdownVariantSidebar', () => {
    it('returns `true` when `state.variant` is "sidebar"', () => {
      expect(getters.isDropdownVariantSidebar({ variant: 'sidebar' })).toBe(true);
    });
  });

  describe('isDropdownVariantStandalone', () => {
    it('returns `true` when `state.variant` is "standalone"', () => {
      expect(getters.isDropdownVariantStandalone({ variant: 'standalone' })).toBe(true);
    });
  });
});
