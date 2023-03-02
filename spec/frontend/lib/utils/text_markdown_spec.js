import $ from 'jquery';
import AxiosMockAdapter from 'axios-mock-adapter';
import {
  insertMarkdownText,
  keypressNoteText,
  compositionStartNoteText,
  compositionEndNoteText,
  updateTextForToolbarBtn,
  resolveSelectedImage,
} from '~/lib/utils/text_markdown';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import '~/lib/utils/jquery_at_who';
import axios from '~/lib/utils/axios_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('init markdown', () => {
  let mdArea;
  let textArea;
  let indentButton;
  let outdentButton;
  let axiosMock;

  beforeAll(() => {
    setHTMLFixture(
      `<div class='md-area'>
        <textarea></textarea>
        <button data-md-command="indentLines" id="indentButton"></button>
        <button data-md-command="outdentLines" id="outdentButton"></button>
      </div>`,
    );
    mdArea = document.querySelector('.md-area');
    textArea = mdArea.querySelector('textarea');
    indentButton = mdArea.querySelector('#indentButton');
    outdentButton = mdArea.querySelector('#outdentButton');

    textArea.focus();

    // needed for the underlying insertText to work
    document.execCommand = jest.fn(() => false);
  });

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  afterAll(() => {
    resetHTMLFixture();
  });

  describe('insertMarkdownText', () => {
    it('will not error if selected text is a number', () => {
      const selected = 2;

      insertMarkdownText({
        textArea,
        text: '',
        tag: '',
        blockTag: null,
        selected,
        wrap: false,
      });

      expect(textArea.value).toBe(selected.toString());
    });
  });

  describe('textArea', () => {
    describe('without selection', () => {
      it('inserts the tag on an empty line', () => {
        const initialValue = '';

        textArea.value = initialValue;
        textArea.selectionStart = 0;
        textArea.selectionEnd = 0;

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '- ',
          blockTag: null,
          selected: '',
          wrap: false,
        });

        expect(textArea.value).toEqual(`${initialValue}- `);
      });

      it('inserts dollar signs correctly', () => {
        const initialValue = '';

        textArea.value = initialValue;
        textArea.selectionStart = 0;
        textArea.selectionEnd = 0;

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '```suggestion:-0+0\n{text}\n```',
          blockTag: true,
          selected: '# Does not parse the `$` currently.',
          wrap: false,
        });

        expect(textArea.value).toContain('# Does not parse the `$` currently.');
      });

      it('inserts the tag on a new line if the current one is not empty', () => {
        const initialValue = 'some text';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '- ',
          blockTag: null,
          selected: '',
          wrap: false,
        });

        expect(textArea.value).toEqual(`${initialValue}\n- `);
      });

      it('unescapes new line characters', () => {
        const initialValue = '';

        textArea.value = initialValue;
        textArea.selectionStart = 0;
        textArea.selectionEnd = 0;

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '```suggestion:-0+0\n{text}\n```',
          blockTag: true,
          selected: '# Does not %br parse the %br currently.',
          wrap: false,
        });

        expect(textArea.value).toContain('# Does not \\n parse the \\n currently.');
      });

      it('inserts the tag on the same line if the current line only contains spaces', () => {
        const initialValue = '  ';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '- ',
          blockTag: null,
          selected: '',
          wrap: false,
        });

        expect(textArea.value).toEqual(`${initialValue}- `);
      });

      it('inserts the tag on the same line if the current line only contains tabs', () => {
        const initialValue = '\t\t\t';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '- ',
          blockTag: null,
          selected: '',
          wrap: false,
        });

        expect(textArea.value).toEqual(`${initialValue}- `);
      });

      it('places the cursor inside the tags', () => {
        const start = 'lorem ';
        const end = ' ipsum';
        const tag = '*';

        textArea.value = `${start}${end}`;
        textArea.setSelectionRange(start.length, start.length);

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag,
          blockTag: null,
          selected: '',
          wrap: true,
        });

        expect(textArea.value).toEqual(`${start}**${end}`);

        // cursor placement should be between tags
        expect(textArea.selectionStart).toBe(start.length + tag.length);
      });

      describe('Continuing markdown lists', () => {
        let enterEvent;

        beforeEach(() => {
          enterEvent = new KeyboardEvent('keydown', { key: 'Enter', cancelable: true });
          textArea.addEventListener('keydown', keypressNoteText);
          textArea.addEventListener('compositionstart', compositionStartNoteText);
          textArea.addEventListener('compositionend', compositionEndNoteText);
          gon.markdown_automatic_lists = true;
        });

        it.each`
          text                           | expected
          ${'- item'}                    | ${'- item\n- '}
          ${'* item'}                    | ${'* item\n* '}
          ${'+ item'}                    | ${'+ item\n+ '}
          ${'- [ ] item'}                | ${'- [ ] item\n- [ ] '}
          ${'- [x] item'}                | ${'- [x] item\n- [ ] '}
          ${'- [X] item'}                | ${'- [X] item\n- [ ] '}
          ${'- [~] item'}                | ${'- [~] item\n- [ ] '}
          ${'- [ ] nbsp (U+00A0)'}       | ${'- [ ] nbsp (U+00A0)\n- [ ] '}
          ${'- item\n  - second'}        | ${'- item\n  - second\n  - '}
          ${'- - -'}                     | ${'- - -'}
          ${'- --'}                      | ${'- --'}
          ${'* **'}                      | ${'* **'}
          ${' **  * ** * ** * **'}       | ${' **  * ** * ** * **'}
          ${'- - -x'}                    | ${'- - -x\n- '}
          ${'+ ++'}                      | ${'+ ++\n+ '}
          ${'1. item'}                   | ${'1. item\n2. '}
          ${'1. [ ] item'}               | ${'1. [ ] item\n2. [ ] '}
          ${'1. [x] item'}               | ${'1. [x] item\n2. [ ] '}
          ${'1. [X] item'}               | ${'1. [X] item\n2. [ ] '}
          ${'1. [~] item'}               | ${'1. [~] item\n2. [ ] '}
          ${'108. item'}                 | ${'108. item\n109. '}
          ${'108. item\n     - second'}  | ${'108. item\n     - second\n     - '}
          ${'108. item\n     1. second'} | ${'108. item\n     1. second\n     2. '}
          ${'non-item, will not change'} | ${'non-item, will not change'}
        `('adds correct list continuation characters', ({ text, expected }) => {
          textArea.value = text;
          textArea.setSelectionRange(text.length, text.length);

          textArea.dispatchEvent(enterEvent);

          expect(textArea.value).toEqual(expected);
          expect(textArea.selectionStart).toBe(expected.length);
        });

        // test that when pressing Enter on an empty list item, the empty
        // list item text is selected, so that when the Enter propagates,
        // it's removed
        it.each`
          text                                     | expected
          ${'- item\n- '}                          | ${'- item\n'}
          ${'- [ ] item\n- [ ] '}                  | ${'- [ ] item\n'}
          ${'- [x] item\n- [x] '}                  | ${'- [x] item\n'}
          ${'- [X] item\n- [X] '}                  | ${'- [X] item\n'}
          ${'- [~] item\n- [~] '}                  | ${'- [~] item\n'}
          ${'- item\n  - second\n  - '}            | ${'- item\n  - second\n'}
          ${'1. item\n2. '}                        | ${'1. item\n'}
          ${'1. [ ] item\n2. [ ] '}                | ${'1. [ ] item\n'}
          ${'1. [x] item\n2. [x] '}                | ${'1. [x] item\n'}
          ${'1. [X] item\n2. [X] '}                | ${'1. [X] item\n'}
          ${'1. [~] item\n2. [~] '}                | ${'1. [~] item\n'}
          ${'108. item\n109. '}                    | ${'108. item\n'}
          ${'108. item\n     - second\n     - '}   | ${'108. item\n     - second\n'}
          ${'108. item\n     1. second\n     1. '} | ${'108. item\n     1. second\n'}
        `('remove list continuation characters', ({ text, expected }) => {
          textArea.value = text;
          textArea.setSelectionRange(text.length, text.length);

          textArea.dispatchEvent(enterEvent);

          expect(textArea.value.substr(0, textArea.selectionStart)).toEqual(expected);
          expect(textArea.selectionStart).toBe(expected.length);
          expect(textArea.selectionEnd).toBe(text.length);
        });

        // test that when we're in the middle of autocomplete, we don't
        // add a new list item
        it.each`
          text          | expected          | atwho_selecting
          ${'- item @'} | ${'- item @'}     | ${true}
          ${'- item @'} | ${'- item @\n- '} | ${false}
        `('behaves correctly during autocomplete', ({ text, expected, atwho_selecting }) => {
          jest.spyOn($.fn, 'atwho').mockReturnValue(atwho_selecting);

          textArea.value = text;
          textArea.setSelectionRange(text.length, text.length);

          textArea.dispatchEvent(enterEvent);

          expect(textArea.value).toEqual(expected);
        });

        it.each`
          text                                                       | add_at | expected
          ${'1. one\n2. two\n3. three'}                              | ${13}  | ${'1. one\n2. two\n2. \n3. three'}
          ${'108. item\n     5. second\n     6. six\n     7. seven'} | ${36}  | ${'108. item\n     5. second\n     6. six\n     6. \n     7. seven'}
        `(
          'adds correct numbered continuation characters when in middle of list',
          ({ text, add_at, expected }) => {
            textArea.value = text;
            textArea.setSelectionRange(add_at, add_at);

            textArea.dispatchEvent(enterEvent);

            expect(textArea.value).toEqual(expected);
          },
        );

        // test that when pressing Enter in the prefix area of a list item,
        // such as between `2.`, we simply propagate the Enter,
        // adding a newline.  Since the event doesn't actually get propagated
        // in the test, check that `defaultPrevented` is false
        it.each`
          text                                     | add_at | prevented
          ${'- one\n- two\n- three'}               | ${6}   | ${false}
          ${'- one\n- two\n- three'}               | ${7}   | ${false}
          ${'- one\n- two\n- three'}               | ${8}   | ${true}
          ${'- [ ] one\n- [ ] two\n- [ ] three'}   | ${10}  | ${false}
          ${'- [ ] one\n- [ ] two\n- [ ] three'}   | ${15}  | ${false}
          ${'- [ ] one\n- [ ] two\n- [ ] three'}   | ${16}  | ${true}
          ${'- [ ] one\n  - [ ] two\n- [ ] three'} | ${10}  | ${false}
          ${'- [ ] one\n  - [ ] two\n- [ ] three'} | ${11}  | ${false}
          ${'- [ ] one\n  - [ ] two\n- [ ] three'} | ${17}  | ${false}
          ${'- [ ] one\n  - [ ] two\n- [ ] three'} | ${18}  | ${true}
          ${'1. one\n2. two\n3. three'}            | ${7}   | ${false}
          ${'1. one\n2. two\n3. three'}            | ${9}   | ${false}
          ${'1. one\n2. two\n3. three'}            | ${10}  | ${true}
        `(
          'allows a newline to be added if cursor is inside the list marker prefix area',
          ({ text, add_at, prevented }) => {
            textArea.value = text;
            textArea.setSelectionRange(add_at, add_at);

            textArea.dispatchEvent(enterEvent);

            expect(enterEvent.defaultPrevented).toBe(prevented);
          },
        );

        it('does not duplicate a line item for IME characters', () => {
          const text = '- 日本語';
          const expected = '- 日本語\n- ';

          textArea.dispatchEvent(new CompositionEvent('compositionstart'));
          textArea.value = text;

          // Press enter to end composition
          textArea.dispatchEvent(enterEvent);
          textArea.dispatchEvent(new CompositionEvent('compositionend'));
          textArea.setSelectionRange(text.length, text.length);

          // Press enter to make new line
          textArea.dispatchEvent(enterEvent);

          expect(textArea.value).toEqual(expected);
          expect(textArea.selectionStart).toBe(expected.length);
        });

        it('does nothing if user preference disabled', () => {
          const text = '- test';

          gon.markdown_automatic_lists = false;

          textArea.value = text;
          textArea.setSelectionRange(text.length, text.length);
          textArea.dispatchEvent(enterEvent);

          expect(textArea.value).toEqual(text);
        });
      });
    });

    describe('shifting selected lines left or right', () => {
      it.each`
        selectionStart | selectionEnd | expected                | expectedSelectionStart | expectedSelectionEnd
        ${0}           | ${0}         | ${'  012\n456\n89'}     | ${2}                   | ${2}
        ${5}           | ${5}         | ${'012\n  456\n89'}     | ${7}                   | ${7}
        ${10}          | ${10}        | ${'012\n456\n  89'}     | ${12}                  | ${12}
        ${0}           | ${2}         | ${'  012\n456\n89'}     | ${0}                   | ${4}
        ${1}           | ${2}         | ${'  012\n456\n89'}     | ${3}                   | ${4}
        ${5}           | ${7}         | ${'012\n  456\n89'}     | ${7}                   | ${9}
        ${0}           | ${7}         | ${'  012\n  456\n89'}   | ${0}                   | ${11}
        ${2}           | ${9}         | ${'  012\n  456\n  89'} | ${4}                   | ${15}
      `(
        'indents the selected lines two spaces to the right',
        ({
          selectionStart,
          selectionEnd,
          expected,
          expectedSelectionStart,
          expectedSelectionEnd,
        }) => {
          const text = '012\n456\n89';
          textArea.value = text;
          textArea.setSelectionRange(selectionStart, selectionEnd);

          updateTextForToolbarBtn($(indentButton));

          expect(textArea.value).toEqual(expected);
          expect(textArea.selectionStart).toEqual(expectedSelectionStart);
          expect(textArea.selectionEnd).toEqual(expectedSelectionEnd);
        },
      );

      it('indents a blank line two spaces to the right', () => {
        textArea.value = '012\n\n89';
        textArea.setSelectionRange(4, 4);

        updateTextForToolbarBtn($(indentButton));

        expect(textArea.value).toEqual('012\n  \n89');
        expect(textArea.selectionStart).toEqual(6);
        expect(textArea.selectionEnd).toEqual(6);
      });

      it.each`
        selectionStart | selectionEnd | expected              | expectedSelectionStart | expectedSelectionEnd
        ${0}           | ${0}         | ${'234\n 789\n  34'}  | ${0}                   | ${0}
        ${3}           | ${3}         | ${'234\n 789\n  34'}  | ${1}                   | ${1}
        ${7}           | ${7}         | ${'  234\n789\n  34'} | ${6}                   | ${6}
        ${0}           | ${3}         | ${'234\n 789\n  34'}  | ${0}                   | ${1}
        ${8}           | ${10}        | ${'  234\n789\n  34'} | ${7}                   | ${9}
        ${14}          | ${15}        | ${'  234\n 789\n34'}  | ${12}                  | ${13}
        ${0}           | ${15}        | ${'234\n789\n34'}     | ${0}                   | ${10}
        ${3}           | ${13}        | ${'234\n789\n34'}     | ${1}                   | ${8}
        ${6}           | ${6}         | ${'  234\n789\n  34'} | ${6}                   | ${6}
      `(
        'outdents the selected lines two spaces to the left',
        ({
          selectionStart,
          selectionEnd,
          expected,
          expectedSelectionStart,
          expectedSelectionEnd,
        }) => {
          const text = '  234\n 789\n  34';
          textArea.value = text;
          textArea.setSelectionRange(selectionStart, selectionEnd);

          updateTextForToolbarBtn($(outdentButton));

          expect(textArea.value).toEqual(expected);
          expect(textArea.selectionStart).toEqual(expectedSelectionStart);
          expect(textArea.selectionEnd).toEqual(expectedSelectionEnd);
        },
      );

      it('outdent a blank line has no effect', () => {
        textArea.value = '012\n\n89';
        textArea.setSelectionRange(4, 4);

        updateTextForToolbarBtn($(outdentButton));

        expect(textArea.value).toEqual('012\n\n89');
        expect(textArea.selectionStart).toEqual(4);
        expect(textArea.selectionEnd).toEqual(4);
      });

      it('does not indent if meta is not set', () => {
        const indentNoMetaEvent = new KeyboardEvent('keydown', { key: ']' });
        const text = '012\n456\n89';
        textArea.value = text;
        textArea.setSelectionRange(0, 0);

        textArea.dispatchEvent(indentNoMetaEvent);

        expect(textArea.value).toEqual(text);
      });

      it.each`
        keyEvent
        ${new KeyboardEvent('keydown', { key: ']', metaKey: false })}
        ${new KeyboardEvent('keydown', { key: ']', metaKey: true, shiftKey: true })}
        ${new KeyboardEvent('keydown', { key: ']', metaKey: true, altKey: true })}
        ${new KeyboardEvent('keydown', { key: ']', metaKey: true, ctrlKey: true })}
      `('does not indent if meta is not set', ({ keyEvent }) => {
        const text = '012\n456\n89';
        textArea.value = text;
        textArea.setSelectionRange(0, 0);

        textArea.dispatchEvent(keyEvent);

        expect(textArea.value).toEqual(text);
      });
    });

    describe('with selection', () => {
      let text = 'initial selected value';
      let selected = 'selected';
      let selectedIndex;

      beforeEach(() => {
        textArea.value = text;
        selectedIndex = text.indexOf(selected);
        textArea.setSelectionRange(selectedIndex, selectedIndex + selected.length);
      });

      it('applies the tag to the selected value', () => {
        const tag = '*';

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag,
          blockTag: null,
          selected,
          wrap: true,
        });

        expect(textArea.value).toEqual(text.replace(selected, `*${selected}*`));

        // cursor placement should be after selection + 2 tag lengths
        expect(textArea.selectionStart).toBe(selectedIndex + selected.length + 2 * tag.length);
      });

      it('replaces the placeholder in the tag', () => {
        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '[{text}](url)',
          blockTag: null,
          selected,
          wrap: false,
        });

        expect(textArea.value).toEqual(text.replace(selected, `[${selected}](url)`));
      });

      describe('surrounds selected text with matching character', () => {
        it.each`
          key    | expected
          ${'['} | ${`[${selected}]`}
          ${'*'} | ${`**${selected}**`}
          ${"'"} | ${`'${selected}'`}
          ${'_'} | ${`_${selected}_`}
          ${'`'} | ${`\`${selected}\``}
          ${'"'} | ${`"${selected}"`}
          ${'{'} | ${`{${selected}}`}
          ${'('} | ${`(${selected})`}
          ${'<'} | ${`<${selected}>`}
        `('generates $expected when $key is pressed', ({ key, expected }) => {
          const event = new KeyboardEvent('keydown', { key });
          gon.markdown_surround_selection = true;

          textArea.addEventListener('keydown', keypressNoteText);
          textArea.dispatchEvent(event);

          expect(textArea.value).toEqual(text.replace(selected, expected));

          // cursor placement should be after selection + 2 tag lengths
          expect(textArea.selectionStart).toBe(selectedIndex + expected.length);
        });

        it('does nothing if user preference disabled', () => {
          const event = new KeyboardEvent('keydown', { key: '[' });
          gon.markdown_surround_selection = false;

          textArea.addEventListener('keydown', keypressNoteText);
          textArea.dispatchEvent(event);

          expect(textArea.value).toEqual(text);
        });

        it('does nothing if meta is set', () => {
          const event = new KeyboardEvent('keydown', { key: '[', metaKey: true });

          textArea.addEventListener('keydown', keypressNoteText);
          textArea.dispatchEvent(event);

          expect(textArea.value).toEqual(text);
        });
      });

      describe('and text to be selected', () => {
        const tag = '[{text}](url)';
        const select = 'url';

        it('selects the text', () => {
          insertMarkdownText({
            textArea,
            text: textArea.value,
            tag,
            blockTag: null,
            selected,
            wrap: false,
            select,
          });

          const expectedText = text.replace(selected, `[${selected}](url)`);

          expect(textArea.value).toEqual(expectedText);
          expect(textArea.selectionStart).toEqual(expectedText.indexOf(select));
          expect(textArea.selectionEnd).toEqual(expectedText.indexOf(select) + select.length);
        });

        it('selects the right text when multiple tags are present', () => {
          const initialValue = `${tag} ${tag} ${selected}`;
          textArea.value = initialValue;
          selectedIndex = initialValue.indexOf(selected);
          textArea.setSelectionRange(selectedIndex, selectedIndex + selected.length);
          insertMarkdownText({
            textArea,
            text: textArea.value,
            tag,
            blockTag: null,
            selected,
            wrap: false,
            select,
          });

          const expectedText = initialValue.replace(selected, `[${selected}](url)`);

          expect(textArea.value).toEqual(expectedText);
          expect(textArea.selectionStart).toEqual(expectedText.lastIndexOf(select));
          expect(textArea.selectionEnd).toEqual(expectedText.lastIndexOf(select) + select.length);
        });

        it('should support selected urls', () => {
          const expectedUrl = 'http://www.gitlab.com';
          const expectedSelectionText = 'text';
          const expectedText = `text [${expectedSelectionText}](${expectedUrl}) text`;
          const initialValue = `text ${expectedUrl} text`;

          textArea.value = initialValue;
          selectedIndex = initialValue.indexOf(expectedUrl);
          textArea.setSelectionRange(selectedIndex, selectedIndex + expectedUrl.length);

          insertMarkdownText({
            textArea,
            text: textArea.value,
            tag,
            blockTag: null,
            selected: expectedUrl,
            wrap: false,
            select,
          });

          expect(textArea.value).toEqual(expectedText);
          expect(textArea.selectionStart).toEqual(expectedText.indexOf(expectedSelectionText, 1));
          expect(textArea.selectionEnd).toEqual(
            expectedText.indexOf(expectedSelectionText, 1) + expectedSelectionText.length,
          );
        });

        it('only converts valid URLs', () => {
          const notValidUrl = 'group::label';
          const expectedUrlValue = 'url';
          const expectedText = `other [${notValidUrl}](${expectedUrlValue}) text`;
          const initialValue = `other ${notValidUrl} text`;

          textArea.value = initialValue;
          selectedIndex = initialValue.indexOf(notValidUrl);
          textArea.setSelectionRange(selectedIndex, selectedIndex + notValidUrl.length);

          insertMarkdownText({
            textArea,
            text: textArea.value,
            tag,
            blockTag: null,
            selected: notValidUrl,
            wrap: false,
            select,
          });

          expect(textArea.value).toEqual(expectedText);
          expect(textArea.selectionStart).toEqual(expectedText.indexOf(expectedUrlValue, 1));
          expect(textArea.selectionEnd).toEqual(
            expectedText.indexOf(expectedUrlValue, 1) + expectedUrlValue.length,
          );
        });

        it('adds block tags on line above and below selection', () => {
          selected = 'this text\nis multiple\nlines';
          text = `before \n${selected}\nafter `;

          textArea.value = text;
          selectedIndex = text.indexOf(selected);
          textArea.setSelectionRange(selectedIndex, selectedIndex + selected.length);

          insertMarkdownText({
            textArea,
            text,
            tag: '',
            blockTag: '***',
            selected,
            wrap: true,
          });

          expect(textArea.value).toEqual(`before \n***\n${selected}\n***\nafter `);
        });

        it('removes block tags on line above and below selection', () => {
          selected = 'this text\nis multiple\nlines';
          text = `before \n***\n${selected}\n***\nafter `;

          textArea.value = text;
          selectedIndex = text.indexOf(selected);
          textArea.setSelectionRange(selectedIndex, selectedIndex + selected.length);

          insertMarkdownText({
            textArea,
            text,
            tag: '',
            blockTag: '***',
            selected,
            wrap: true,
          });

          expect(textArea.value).toEqual(`before \n${selected}\nafter `);
        });
      });
    });
  });

  describe('resolveSelectedImage', () => {
    const markdownPreviewPath = '/markdown/preview';
    const imageMarkdown = '![image](/uploads/image.png)';
    const imageAbsoluteUrl = '/abs/uploads/image.png';

    describe('when textarea cursor is positioned on an image', () => {
      beforeEach(() => {
        axiosMock.onPost(markdownPreviewPath, { text: imageMarkdown }).reply(HTTP_STATUS_OK, {
          body: `
        <p><a href="${imageAbsoluteUrl}"><img src="${imageAbsoluteUrl}"></a></p>
        `,
        });
      });

      it('returns the image absolute URL, markdown, and filename', async () => {
        textArea.value = `image ${imageMarkdown}`;
        textArea.setSelectionRange(8, 8);
        expect(await resolveSelectedImage(textArea, markdownPreviewPath)).toEqual({
          imageURL: imageAbsoluteUrl,
          imageMarkdown,
          filename: 'image.png',
        });
      });
    });

    describe('when textarea cursor is not positioned on an image', () => {
      it.each`
        markdown                    | selectionRange
        ${`image ${imageMarkdown}`} | ${[4, 4]}
        ${`!2 (issue)`}             | ${[2, 2]}
      `('returns null', async ({ markdown, selectionRange }) => {
        textArea.value = markdown;
        textArea.setSelectionRange(...selectionRange);
        expect(await resolveSelectedImage(textArea, markdownPreviewPath)).toBe(null);
      });
    });

    describe('when textarea cursor is positioned between images', () => {
      it('returns null', async () => {
        const position = imageMarkdown.length + 1;

        textArea.value = `${imageMarkdown}\n\n${imageMarkdown}`;
        textArea.setSelectionRange(position, position);

        expect(await resolveSelectedImage(textArea, markdownPreviewPath)).toBe(null);
      });
    });
  });

  describe('Source Editor', () => {
    let editor;

    beforeEach(() => {
      editor = {
        getSelection: jest.fn().mockReturnValue({
          startLineNumber: 1,
          startColumn: 1,
          endLineNumber: 2,
          endColumn: 2,
        }),
        getValue: jest.fn().mockReturnValue('this is text \n in two lines'),
        selectWithinSelection: jest.fn(),
        replaceSelectedText: jest.fn(),
        moveCursor: jest.fn(),
      };
    });

    it('replaces selected text', () => {
      insertMarkdownText({
        text: editor.getValue,
        tag: '*',
        blockTag: null,
        selected: '',
        wrap: false,
        editor,
      });

      expect(editor.replaceSelectedText).toHaveBeenCalled();
    });

    it('adds block tags on line above and below selection', () => {
      const selected = 'this text \n is multiple \n lines';
      const text = `before \n ${selected} \n after`;

      insertMarkdownText({
        text,
        tag: '',
        blockTag: '***',
        selected,
        wrap: true,
        editor,
      });

      expect(editor.replaceSelectedText).toHaveBeenCalledWith(`***\n${selected}\n***\n`, undefined);
    });

    it('removes block tags on line above and below selection', () => {
      const selected = 'this text\nis multiple\nlines';
      const text = `before\n***\n${selected}\n***\nafter`;

      editor.getSelection = jest.fn().mockReturnValue({
        startLineNumber: 2,
        startColumn: 1,
        endLineNumber: 4,
        endColumn: 2,
        setSelectionRange: jest.fn(),
      });

      insertMarkdownText({
        text,
        tag: '',
        blockTag: '***',
        selected,
        wrap: true,
        editor,
      });

      expect(editor.replaceSelectedText).toHaveBeenCalledWith(`${selected}\n`, undefined);
    });

    it('uses editor to navigate back tag length when nothing is selected', () => {
      editor.getSelection = jest.fn().mockReturnValue({
        startLineNumber: 1,
        startColumn: 1,
        endLineNumber: 1,
        endColumn: 1,
      });

      insertMarkdownText({
        text: editor.getValue,
        tag: '*',
        blockTag: null,
        selected: '',
        wrap: true,
        editor,
      });

      expect(editor.moveCursor).toHaveBeenCalledWith(-1);
    });

    it('editor does not navigate back when there is selected text', () => {
      insertMarkdownText({
        text: editor.getValue,
        tag: '*',
        blockTag: null,
        selected: 'foobar',
        wrap: true,
        editor,
      });

      expect(editor.selectWithinSelection).not.toHaveBeenCalled();
    });
  });
});
