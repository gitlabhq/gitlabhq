import { setHTMLFixture } from 'helpers/fixtures';
import {
  convertDescriptionWithNewSort,
  deleteTaskListItem,
  extractTaskTitleAndDescription,
  insertNextToTaskListItemText,
} from '~/issues/show/utils';

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

  describe('deleteTaskListItem', () => {
    const description = `Tasks

1. [ ] item 1
   1. [ ] item 2
   1. [ ] item 3
      1. [ ] item 4
      1. [ ] item 5
   1. [ ] item 6

      paragraph text

   1. [ ] item 7

      paragraph text

      1. [ ] item 8

         paragraph text

      1. [ ] item 9
   1. [ ] item 10`;

    /* The equivalent HTML for the above markdown
    <ol data-sourcepos="3:1-21:17">
      <li data-sourcepos="3:1-21:17">item 1
        <ol data-sourcepos="4:4-21:17">
          <li data-sourcepos="4:4-4:16">
            <p data-sourcepos="4:7-4:16">item 2</p>
          </li>
          <li data-sourcepos="5:4-7:19">
            <p data-sourcepos="5:7-5:16">item 3</p>
            <ol data-sourcepos="6:7-7:19">
              <li data-sourcepos="6:7-6:19">item 4</li>
              <li data-sourcepos="7:7-7:19">item 5</li>
            </ol>
          </li>
          <li data-sourcepos="8:4-11:0">
            <p data-sourcepos="8:7-8:16">item 6</p>
            <p data-sourcepos="10:7-10:20">paragraph text</p>
          </li>
          <li data-sourcepos="12:4-20:19">
            <p data-sourcepos="12:7-12:16">item 7</p>
            <p data-sourcepos="14:7-14:20">paragraph text</p>
            <ol data-sourcepos="16:7-20:19">
              <li data-sourcepos="16:7-19:0">
                <p data-sourcepos="16:10-16:19">item 8</p>
                <p data-sourcepos="18:10-18:23">paragraph text</p>
              </li>
              <li data-sourcepos="20:7-20:19">
                <p data-sourcepos="20:10-20:19">item 9</p>
              </li>
            </ol>
          </li>
          <li data-sourcepos="21:4-21:17">
            <p data-sourcepos="21:7-21:17">item 10</p>
          </li>
        </ol>
      </li>
    </ol>
    */

    it('deletes item with no children', () => {
      const sourcepos = '4:4-4:14';
      const newDescription = `Tasks

1. [ ] item 1
   1. [ ] item 3
      1. [ ] item 4
      1. [ ] item 5
   1. [ ] item 6

      paragraph text

   1. [ ] item 7

      paragraph text

      1. [ ] item 8

         paragraph text

      1. [ ] item 9
   1. [ ] item 10`;

      expect(deleteTaskListItem(description, sourcepos)).toEqual({
        newDescription,
        taskTitle: 'item 2',
      });
    });

    it('deletes deeply nested item with no children', () => {
      const sourcepos = '6:7-6:19';
      const newDescription = `Tasks

1. [ ] item 1
   1. [ ] item 2
   1. [ ] item 3
      1. [ ] item 5
   1. [ ] item 6

      paragraph text

   1. [ ] item 7

      paragraph text

      1. [ ] item 8

         paragraph text

      1. [ ] item 9
   1. [ ] item 10`;

      expect(deleteTaskListItem(description, sourcepos)).toEqual({
        newDescription,
        taskTitle: 'item 4',
      });
    });

    it('deletes item with children and moves sub-tasks up a level', () => {
      const sourcepos = '5:4-7:19';
      const newDescription = `Tasks

1. [ ] item 1
   1. [ ] item 2
   1. [ ] item 4
   1. [ ] item 5
   1. [ ] item 6

      paragraph text

   1. [ ] item 7

      paragraph text

      1. [ ] item 8

         paragraph text

      1. [ ] item 9
   1. [ ] item 10`;

      expect(deleteTaskListItem(description, sourcepos)).toEqual({
        newDescription,
        taskTitle: 'item 3',
      });
    });

    it('deletes item with associated paragraph text', () => {
      const sourcepos = '8:4-11:0';
      const newDescription = `Tasks

1. [ ] item 1
   1. [ ] item 2
   1. [ ] item 3
      1. [ ] item 4
      1. [ ] item 5
   1. [ ] item 7

      paragraph text

      1. [ ] item 8

         paragraph text

      1. [ ] item 9
   1. [ ] item 10`;
      const taskDescription = `
paragraph text
`;

      expect(deleteTaskListItem(description, sourcepos)).toEqual({
        newDescription,
        taskDescription,
        taskTitle: 'item 6',
      });
    });

    it('deletes item with associated paragraph text and moves sub-tasks up a level', () => {
      const sourcepos = '12:4-20:19';
      const newDescription = `Tasks

1. [ ] item 1
   1. [ ] item 2
   1. [ ] item 3
      1. [ ] item 4
      1. [ ] item 5
   1. [ ] item 6

      paragraph text

   1. [ ] item 8

      paragraph text

   1. [ ] item 9
   1. [ ] item 10`;
      const taskDescription = `
paragraph text
`;

      expect(deleteTaskListItem(description, sourcepos)).toEqual({
        newDescription,
        taskDescription,
        taskTitle: 'item 7',
      });
    });
  });

  describe('extractTaskTitleAndDescription', () => {
    const description = `A multi-line
description`;

    describe('when title is pure code block', () => {
      const title = '`code block`';

      it('moves the title to the description', () => {
        expect(extractTaskTitleAndDescription(title)).toEqual({
          title: 'Untitled',
          description: title,
        });
      });

      it('moves the title to the description and appends the description to it', () => {
        expect(extractTaskTitleAndDescription(title, description)).toEqual({
          title: 'Untitled',
          description: `${title}\n\n${description}`,
        });
      });
    });

    describe('when title is too long', () => {
      const title =
        'Deleniti id facere numquam cum consectetur sint ipsum consequatur. Odit nihil harum consequuntur est nemo adipisci. Incidunt suscipit voluptatem et culpa at voluptatem consequuntur. Rerum aliquam earum quia consequatur ipsam quae ut. Quod molestias ducimus quia ratione nostrum ut adipisci.';
      const expectedTitle =
        'Deleniti id facere numquam cum consectetur sint ipsum consequatur. Odit nihil harum consequuntur est nemo adipisci. Incidunt suscipit voluptatem et culpa at voluptatem consequuntur. Rerum aliquam earum quia consequatur ipsam quae ut. Quod molestias ducimu';

      it('moves the title beyond the character limit to the description', () => {
        expect(extractTaskTitleAndDescription(title)).toEqual({
          title: expectedTitle,
          description: 's quia ratione nostrum ut adipisci.',
        });
      });

      it('moves the title beyond the character limit to the description and appends the description to it', () => {
        expect(extractTaskTitleAndDescription(title, description)).toEqual({
          title: expectedTitle,
          description: `s quia ratione nostrum ut adipisci.\n\n${description}`,
        });
      });
    });

    describe('when title is fine', () => {
      const title = 'A fine title';

      it('uses the title with no modifications', () => {
        expect(extractTaskTitleAndDescription(title)).toEqual({ title });
      });

      it('uses the title and description with no modifications', () => {
        expect(extractTaskTitleAndDescription(title, description)).toEqual({ title, description });
      });
    });
  });
});

describe('insertNextToTaskListItemText', () => {
  const dropdown = document.createElement('div');
  dropdown.classList.add('dropdown');

  describe('when simple checkbox with text', () => {
    it('inserts element as sibling to checkbox, last child of ul element', () => {
      setHTMLFixture(`
        <div class="description">
          <div class="md">
            <ul data-sourcepos="1:1-1:9" class="task-list">
              <li data-sourcepos="1:1-1:9" class="task-list-item">
                <input type="checkbox" class="task-list-item-checkbox">
                one
              </li>
            </ul>
          </div>
        </div>
      `);
      const listItem = document.querySelector('.task-list-item');
      insertNextToTaskListItemText(dropdown, listItem);

      expect(listItem.lastChild).toBe(dropdown);
    });
  });

  describe('when checkbox with nested checkbox', () => {
    it('inserts element as sibling to checkbox, before the nested checkbox', () => {
      setHTMLFixture(`
        <div class="description">
          <div class="md">
            <ul data-sourcepos="1:1-1:9" class="task-list">
              <li data-sourcepos="1:1-3:14" class="task-list-item">
                <input type="checkbox" class="task-list-item-checkbox">
                one
                <ul data-sourcepos="2:3-3:14" class="task-list">
                  <li data-sourcepos="2:3-2:14" class="task-list-item">
                    <input type="checkbox" class="task-list-item-checkbox">
                    two
                  </li>
                  <li data-sourcepos="3:3-3:14" class="task-list-item enabled">
                    <input type="checkbox" class="task-list-item-checkbox">
                    three
                  </li>
                </ul>
              </li>
            </ul>
          </div>
        </div>
      `);
      const listItem = document.querySelector('.task-list-item');
      insertNextToTaskListItemText(dropdown, listItem);

      expect(listItem.lastElementChild.previousSibling).toBe(dropdown);
    });
  });

  describe('when multi-paragraph checkbox', () => {
    it('inserts element as sibling to checkbox, inside p element', () => {
      setHTMLFixture(`
        <div class="description">
          <div class="md">
            <ul data-sourcepos="1:1-1:9" class="task-list">
              <li data-sourcepos="1:1-3:11" class="task-list-item">
                <p data-sourcepos="1:3-1:9">
                  <input type="checkbox" class="task-list-item-checkbox">
                  one
                </p>
                <p data-sourcepos="3:3-3:11">
                  paragraph
                </p>
              </li>
            </ul>
          </div>
        </div>
      `);
      const listItem = document.querySelector('.task-list-item');
      insertNextToTaskListItemText(dropdown, listItem);

      expect(listItem.firstElementChild.lastElementChild).toBe(dropdown);
    });
  });
});
