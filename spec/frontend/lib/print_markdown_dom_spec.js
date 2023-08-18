import printJS from 'print-js';
import printMarkdownDom from '~/lib/print_markdown_dom';

jest.mock('print-js', () => jest.fn());

describe('print util', () => {
  describe('print markdown dom', () => {
    beforeEach(() => {
      document.body.innerHTML = `<div id='target'></div>`;
    });

    const getTarget = () => document.getElementById('target');

    const contentValues = [
      {
        title: 'test title',
        expectedTitle: '<h2 class="gl-mt-0 gl-mb-5">test title</h2>',
        content: '',
        expectedContent: '<div class="md"></div>',
      },
      {
        title: 'test title',
        expectedTitle: '<h2 class="gl-mt-0 gl-mb-5">test title</h2>',
        content: '<p>test content</p>',
        expectedContent: '<div class="md"><p>test content</p></div>',
      },
      {
        title: 'test title',
        expectedTitle: '<h2 class="gl-mt-0 gl-mb-5">test title</h2>',
        content: '<details><summary>test detail</summary><p>test detail content</p></details>',
        expectedContent:
          '<div class="md"><details open=""><summary>test detail</summary><p>test detail content</p></details></div>',
      },
      {
        title: undefined,
        expectedTitle: '',
        content: '',
        expectedContent: '<div class="md"></div>',
      },
      {
        title: undefined,
        expectedTitle: '',
        content: '<p>test content</p>',
        expectedContent: '<div class="md"><p>test content</p></div>',
      },
      {
        title: undefined,
        expectedTitle: '',
        content: '<details><summary>test detail</summary><p>test detail content</p></details>',
        expectedContent:
          '<div class="md"><details open=""><summary>test detail</summary><p>test detail content</p></details></div>',
      },
    ];

    it.each(contentValues)(
      'should print with title ($title) and content ($content)',
      async ({ title, expectedTitle, content, expectedContent }) => {
        const target = getTarget();
        target.innerHTML = content;
        const stylesheet = 'test stylesheet';

        await printMarkdownDom({
          target,
          title,
          stylesheet,
        });

        expect(printJS).toHaveBeenCalledWith({
          printable: expectedTitle + expectedContent,
          type: 'raw-html',
          documentTitle: title,
          scanStyles: false,
          css: stylesheet,
        });
      },
    );
  });

  describe('ignore selectors', () => {
    beforeEach(() => {
      document.body.innerHTML = `<div id='target'><div><div class='ignore-me'></div></div></div>`;
    });

    it('should ignore dom if ignoreSelectors', async () => {
      const target = document.getElementById('target');
      const ignoreSelectors = ['.ignore-me'];

      await printMarkdownDom({
        target,
        ignoreSelectors,
      });

      expect(printJS).toHaveBeenCalledWith({
        printable: '<div class="md"><div></div></div>',
        type: 'raw-html',
        documentTitle: undefined,
        scanStyles: false,
        css: [],
      });
    });
  });
});
