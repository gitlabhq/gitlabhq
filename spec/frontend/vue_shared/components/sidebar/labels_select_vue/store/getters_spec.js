import * as getters from '~/vue_shared/components/sidebar/labels_select_vue/store/getters';

describe('LabelsSelect Getters', () => {
  describe('dropdownButtonText', () => {
    it('returns string "Label" when state.labels has no selected labels', () => {
      const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];

      expect(getters.dropdownButtonText({ labels })).toBe('Label');
    });

    it('returns label title when state.labels has only 1 label', () => {
      const labels = [{ id: 1, title: 'Foobar', set: true }];

      expect(getters.dropdownButtonText({ labels })).toBe('Foobar');
    });

    it('returns first label title and remaining labels count when state.labels has more than 1 label', () => {
      const labels = [{ id: 1, title: 'Foo', set: true }, { id: 2, title: 'Bar', set: true }];

      expect(getters.dropdownButtonText({ labels })).toBe('Foo +1 more');
    });
  });

  describe('selectedLabelsList', () => {
    it('returns array of IDs of all labels within `state.selectedLabels`', () => {
      const selectedLabels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];

      expect(getters.selectedLabelsList({ selectedLabels })).toEqual([1, 2, 3, 4]);
    });
  });
});
