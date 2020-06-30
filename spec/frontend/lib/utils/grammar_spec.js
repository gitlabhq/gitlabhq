import * as grammar from '~/lib/utils/grammar';

describe('utils/grammar', () => {
  describe('toNounSeriesText', () => {
    it('with empty items returns empty string', () => {
      expect(grammar.toNounSeriesText([])).toBe('');
    });

    it('with single item returns item', () => {
      const items = ['Lorem & Ipsum'];

      expect(grammar.toNounSeriesText(items)).toBe(items[0]);
    });

    it('with 2 items returns item1 and item2', () => {
      const items = ['Dolar', 'Sit & Amit'];

      expect(grammar.toNounSeriesText(items)).toBe(`${items[0]} and ${items[1]}`);
    });

    it('with 3 items returns comma separated series', () => {
      const items = ['Lorem', 'Ipsum', 'Sit & Amit'];
      const expected = 'Lorem, Ipsum, and Sit & Amit';

      expect(grammar.toNounSeriesText(items)).toBe(expected);
    });

    it('with 6 items returns comma separated series', () => {
      const items = ['Lorem', 'ipsum', 'dolar', 'sit', 'amit', 'consectetur & adipiscing'];
      const expected = 'Lorem, ipsum, dolar, sit, amit, and consectetur & adipiscing';

      expect(grammar.toNounSeriesText(items)).toBe(expected);
    });
  });
});
