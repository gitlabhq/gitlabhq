import markdownDeserializer from '~/content_editor/services/gl_api_markdown_deserializer';
import { getFullSource } from '~/content_editor/services/markdown_sourcemap';
import {
  BULLET_LIST_MARKDOWN,
  BULLET_LIST_HTML,
  MALFORMED_BULLET_LIST_HTML,
  BULLET_TASK_LIST_MARKDOWN,
  BULLET_TASK_LIST_HTML,
  PARAGRAPHS_MARKDOWN,
  PARAGRAPHS_HTML,
} from '../test_constants';
import { tiptapEditor, builders, text, doc } from '../serialization_utils';

const { bulletList, listItem, taskList, taskItem, paragraph, bold, italic, strike, code } =
  builders;

const sourceAttrs = jest.fn().mockImplementation((sourceTagName, sourceMapKey, sourceMarkdown) => ({
  sourceTagName,
  sourceMapKey,
  sourceMarkdown,
}));

const bulletListDoc = () =>
  doc(
    bulletList(
      { bullet: '+', ...sourceAttrs('ul', '1:1-3:24', BULLET_LIST_MARKDOWN) },
      listItem(sourceAttrs('li', '1:1-1:13', '+ list item 1'), paragraph('list item 1')),
      listItem(
        sourceAttrs('li', '2:1-3:24', '+ list item 2\n  - embedded list item 3'),
        paragraph('list item 2'),
        bulletList(
          { bullet: '-', ...sourceAttrs('ul', '3:3-3:24', '- embedded list item 3') },
          listItem(
            sourceAttrs('li', '3:3-3:24', '- embedded list item 3'),
            paragraph('embedded list item 3'),
          ),
        ),
      ),
    ),
  );

const bulletListDocWithMalformedSourcepos = () =>
  doc(
    bulletList(
      { bullet: '+', ...sourceAttrs('ul', '1:1-3:24', BULLET_LIST_MARKDOWN) },
      listItem(sourceAttrs('li', '1:1-1:13', '+ list item 1'), paragraph('list item 1')),
      listItem(
        // source not included for out of bounds list item here
        sourceAttrs('li', '5:1-5:24'),
        paragraph('list item 2'),
        bulletList(
          { bullet: '-', ...sourceAttrs('ul', '3:3-3:24', '- embedded list item 3') },
          listItem(
            sourceAttrs('li', '3:3-3:24', '- embedded list item 3'),
            paragraph('embedded list item 3'),
          ),
        ),
      ),
    ),
  );

const bulletTaskListDoc = () =>
  doc(
    taskList(
      { bullet: '-', ...sourceAttrs('ul', '1:1-4:36', BULLET_TASK_LIST_MARKDOWN) },
      taskItem(sourceAttrs('li', '1:1-1:17', '- [ ] list item 1'), paragraph('list item 1')),
      taskItem(
        {
          ...sourceAttrs(
            'li',
            '2:1-4:36',
            '+ [x] checked list item 2\n  + [ ] embedded list item 1\n  - [x] checked embedded list item 2',
          ),
          checked: true,
        },
        paragraph('checked list item 2'),
        taskList(
          {
            bullet: '+',
            ...sourceAttrs(
              'ul',
              '3:3-4:36',
              '+ [ ] embedded list item 1\n  - [x] checked embedded list item 2',
            ),
          },
          taskItem(
            sourceAttrs('li', '3:3-3:28', '+ [ ] embedded list item 1'),
            paragraph('embedded list item 1'),
          ),
          taskItem(
            {
              ...sourceAttrs('li', '4:3-4:36', '- [x] checked embedded list item 2'),
              checked: true,
            },
            paragraph('checked embedded list item 2'),
          ),
        ),
      ),
    ),
  );

const paragraphsDoc = () =>
  doc(
    paragraph(
      sourceAttrs(
        'p',
        '1:1-1:233',
        'You could bold with **asterisks** or you could bold with __underscores__. You could even bold with <strong>strong</strong> or <b>b</b> html tags. You could add newlines in your paragraph, or `code` tags with `` nested `backticks` ``.',
      ),
      text('You could bold with '),
      bold(sourceAttrs('strong', '1:21-1:33', '**asterisks**'), 'asterisks'),
      text(' or you could bold with '),
      bold(sourceAttrs('strong', '1:58-1:72', '__underscores__'), 'underscores'),
      text('. You could even bold with '),
      bold(sourceAttrs('strong'), 'strong'),
      text(' or '),
      bold(sourceAttrs('b'), 'b'),
      text(' html tags. You could add newlines in your paragraph, or '),
      code(sourceAttrs('code', '1:193-1:196', 'code'), 'code'),
      text(' tags with '),
      code(sourceAttrs('code', '1:211-1:230', ' nested `backticks` '), 'nested `backticks`'),
      text('.'),
    ),
    paragraph(
      sourceAttrs(
        'p',
        '3:1-3:144',
        'You could italicise with *asterisks* or you could italicise with _underscores_. You could even italicise with <em>em</em> or <i>i</i> html tags.',
      ),
      text('You could italicise with '),
      italic(sourceAttrs('em', '3:26-3:36', '*asterisks*'), 'asterisks'),
      text(' or you could italicise with '),
      italic(sourceAttrs('em', '3:66-3:78', '_underscores_'), 'underscores'),
      text('. You could even italicise with '),
      italic(sourceAttrs('em'), 'em'),
      text(' or '),
      italic(sourceAttrs('i'), 'i'),
      text(' html tags.'),
    ),
    paragraph(
      sourceAttrs(
        'p',
        '5:1-5:154',
        "As long as you don't touch a paragraph, it will ~~discard~~ <s>destroy</s> <del>delete</del> <strike>remove</strike> preserve the original markdown style.",
      ),
      text("As long as you don't touch a paragraph, it will "),
      strike(sourceAttrs('del', '5:49-5:59', '~~discard~~'), 'discard'),
      text(' '),
      strike({ ...sourceAttrs('s'), htmlTag: 's' }, 'destroy'),
      text(' '),
      strike(sourceAttrs('del'), 'delete'),
      text(' '),
      strike({ ...sourceAttrs('strike'), htmlTag: 'strike' }, 'remove'),
      text(' preserve the original markdown style.'),
    ),
  );

describe('content_editor/services/markdown_sourcemap', () => {
  describe('getFullSource', () => {
    it.each`
      lastChild                                                                | expected
      ${null}                                                                  | ${[]}
      ${{ nodeName: 'paragraph' }}                                             | ${[]}
      ${{ nodeName: '#comment', textContent: null }}                           | ${[]}
      ${{ nodeName: '#comment', textContent: '+ list item 1\n+ list item 2' }} | ${['+ list item 1', '+ list item 2']}
    `('with lastChild=$lastChild, returns $expected', ({ lastChild, expected }) => {
      const element = {
        ownerDocument: {
          body: {
            lastChild,
          },
        },
      };

      expect(getFullSource(element)).toEqual(expected);
    });
  });

  describe('when preserveMarkdown feature is enabled', () => {
    beforeEach(() => {
      gon.features = { preserveMarkdown: true };
    });

    afterEach(() => {
      gon.features = {};
    });

    it.each`
      description                               | sourceMarkdown               | sourceHTML                    | expectedDoc
      ${'bullet list'}                          | ${BULLET_LIST_MARKDOWN}      | ${BULLET_LIST_HTML}           | ${bulletListDoc}
      ${'bullet list with malformed sourcepos'} | ${BULLET_LIST_MARKDOWN}      | ${MALFORMED_BULLET_LIST_HTML} | ${bulletListDocWithMalformedSourcepos}
      ${'bullet task list'}                     | ${BULLET_TASK_LIST_MARKDOWN} | ${BULLET_TASK_LIST_HTML}      | ${bulletTaskListDoc}
      ${'paragraphs with inline elements'}      | ${PARAGRAPHS_MARKDOWN}       | ${PARAGRAPHS_HTML}            | ${paragraphsDoc}
    `(
      'gets markdown source for a rendered $description',
      async ({ sourceMarkdown, sourceHTML, expectedDoc }) => {
        const { document } = await markdownDeserializer({
          render: () => ({
            body: sourceHTML,
          }),
        }).deserialize({
          schema: tiptapEditor.schema,
          markdown: sourceMarkdown,
        });

        expect(document.content.toJSON()).toEqual(expectedDoc().content.toJSON());
      },
    );
  });

  describe('when preserveMarkdown feature is disabled', () => {
    beforeEach(() => {
      sourceAttrs.mockImplementation(() => ({}));
    });

    it.each`
      description                               | sourceMarkdown               | sourceHTML                    | expectedDoc
      ${'bullet list'}                          | ${BULLET_LIST_MARKDOWN}      | ${BULLET_LIST_HTML}           | ${bulletListDoc}
      ${'bullet list with malformed sourcepos'} | ${BULLET_LIST_MARKDOWN}      | ${MALFORMED_BULLET_LIST_HTML} | ${bulletListDocWithMalformedSourcepos}
      ${'bullet task list'}                     | ${BULLET_TASK_LIST_MARKDOWN} | ${BULLET_TASK_LIST_HTML}      | ${bulletTaskListDoc}
      ${'paragraphs with inline elements'}      | ${PARAGRAPHS_MARKDOWN}       | ${PARAGRAPHS_HTML}            | ${paragraphsDoc}
    `(
      'does not include any source information for $description',
      async ({ sourceMarkdown, sourceHTML, expectedDoc }) => {
        const { document } = await markdownDeserializer({
          render: () => ({
            body: sourceHTML,
          }),
        }).deserialize({
          schema: tiptapEditor.schema,
          markdown: sourceMarkdown,
        });

        expect(document.content.toJSON()).toEqual(expectedDoc().content.toJSON());
      },
    );
  });
});
