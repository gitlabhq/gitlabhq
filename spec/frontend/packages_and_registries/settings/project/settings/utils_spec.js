import {
  formOptionsGenerator,
  optionLabelGenerator,
  olderThanTranslationGenerator,
} from '~/packages_and_registries/settings/project/utils';

describe('Utils', () => {
  describe('optionLabelGenerator', () => {
    it('returns an array with a set label', () => {
      const result = optionLabelGenerator(
        [{ variable: 1 }, { variable: 2 }],
        olderThanTranslationGenerator,
      );
      expect(result).toEqual([
        { key: null, label: '' },
        { variable: 1, label: '1 day' },
        { variable: 2, label: '2 days' },
      ]);
    });
  });

  describe('formOptionsGenerator', () => {
    it('returns an object containing olderThan', () => {
      expect(formOptionsGenerator().olderThan).toBeDefined();
      expect(formOptionsGenerator().olderThan).toMatchSnapshot();
    });

    it('returns an object containing cadence', () => {
      expect(formOptionsGenerator().cadence).toBeDefined();
      expect(formOptionsGenerator().cadence).toMatchSnapshot();
    });

    it('returns an object containing keepN', () => {
      expect(formOptionsGenerator().keepN).toBeDefined();
      expect(formOptionsGenerator().keepN).toMatchSnapshot();
    });
  });
});
