import { convertDescriptionWithNewSort } from '~/issues/show/utils';

describe('app/assets/javascripts/issues/show/utils.js', () => {
  describe('convertDescriptionWithNewSort', () => {
    it('converts markdown description with nested lists with new list sort order', () => {
      const description = `I am text

- Item 1
- Item 2
  - Item 3
  - Item 4
- Item 5`;

      // Drag Item 2 + children to Item 1's position
      const html = `<ul data-sourcepos="3:1-7:8">
        <li data-sourcepos="4:1-6:10">
          Item 2
          <ul data-sourcepos="5:3-6:10">
            <li data-sourcepos="5:3-5:10">Item 3</li>
            <li data-sourcepos="6:3-6:10">Item 4</li>
          </ul>
        </li>
        <li data-sourcepos="3:1-3:8">Item 1</li>
        <li data-sourcepos="7:1-7:8">Item 5</li>
      </ul>`;
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

    it('converts markdown description with multi-line list items with new list sort order', () => {
      const description = `Labore ea omnis et officia excepturi.

1. Item 1

   Item 1 part 2

1. Item 2
   - Item 2.1
     - Item 2.1.1
     - Item 2.1.2
   - Item 2.2
   - Item 2.3
1. Item 3
1. Item 4

   \`\`\`
   const variable = 'string';
   \`\`\`

   ![iii](img.jpg)

   last paragraph

1. Item 5
1. Item 6`;

      // Drag Item 2 + children to Item 5's position
      const html = `<ol data-sourcepos="3:1-25:7">
        <li data-sourcepos="3:1-6:0">
          <p data-sourcepos="3:4-3:7">Item 1</p>
          <p data-sourcepos="5:4-5:8">Item 1 part 2</p>
        </li>
        <li data-sourcepos="13:1-13:7">
          <p data-sourcepos="13:4-13:7">Item 3</p>
        </li>
        <li data-sourcepos="14:1-23:0">
          <p data-sourcepos="14:4-14:7">Item 4</p>
          <div>
            <pre data-sourcepos="16:4-18:6">
              <code><span lang="plaintext">const variabl = 'string';</span></code>
            </pre>
          </div>
          <p data-sourcepos="20:4-20:32">
            <a href="href"><img src="img.jpg" alt="description" /></a>
          </p>
          <p data-sourcepos="22:4-22:17">last paragraph</p>
        </li>
        <li data-sourcepos="24:1-24:7">
          <p data-sourcepos="24:4-24:7">Item 5</p>
        </li>
        <li data-sourcepos="7:1-12:10">
          <p data-sourcepos="7:4-7:7">Item 2</p>
          <ul data-sourcepos="8:4-12:10">
            <li data-sourcepos="8:4-10:15">Item 2.1
              <ul data-sourcepos="9:6-10:15">
                <li data-sourcepos="9:6-9:12">Item 2.1.1</li>
                <li data-sourcepos="10:6-10:15">Item 2.1.2</li>
              </ul>
            </li>
            <li data-sourcepos="11:4-11:10">Item 2.2</li>
            <li data-sourcepos="12:4-12:10">Item 2.3</li>
          </ul>
        </li>
        <li data-sourcepos="25:1-25:7">
          <p data-sourcepos="25:4-25:7">Item 6</p>
        </li>
      </ol>`;
      const list = document.createElement('div');
      list.innerHTML = html;

      const expected = `Labore ea omnis et officia excepturi.

1. Item 1

   Item 1 part 2

1. Item 3
1. Item 4

   \`\`\`
   const variable = 'string';
   \`\`\`

   ![iii](img.jpg)

   last paragraph

1. Item 5
1. Item 2
   - Item 2.1
     - Item 2.1.1
     - Item 2.1.2
   - Item 2.2
   - Item 2.3
1. Item 6`;

      expect(convertDescriptionWithNewSort(description, list.firstChild)).toBe(expected);
    });
  });
});
