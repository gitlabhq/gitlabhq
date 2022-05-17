import { convertDescriptionWithNewSort } from '~/issues/show/utils';

describe('app/assets/javascripts/issues/show/utils.js', () => {
  describe('convertDescriptionWithNewSort', () => {
    it('converts markdown description with new list sort order', () => {
      const description = `I am text

- Item 1
- Item 2
  - Item 3
  - Item 4
- Item 5`;

      // Drag Item 2 + children to Item 1's position
      const html = `<ul data-sourcepos="3:1-8:0">
        <li data-sourcepos="4:1-4:8">
          Item 2
          <ul data-sourcepos="5:1-6:10">
            <li data-sourcepos="5:1-5:10">Item 3</li>
            <li data-sourcepos="6:1-6:10">Item 4</li>
          </ul>
        </li>
        <li data-sourcepos="3:1-3:8">Item 1</li>
        <li data-sourcepos="7:1-8:0">Item 5</li>
      <ul>`;
      const list = document.createElement('div');
      list.innerHTML = html;

      const expected = `I am text

- Item 2
  - Item 3
  - Item 4
- Item 1
- Item 5`;

      expect(convertDescriptionWithNewSort(description, list.firstChild)).toBe(expected);
    });
  });
});
