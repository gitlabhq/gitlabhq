import { insertMarkdownText } from '~/lib/utils/text_markdown';

describe('init markdown', () => {
  let textArea;

  beforeAll(() => {
    textArea = document.createElement('textarea');
    document.querySelector('body').appendChild(textArea);
    textArea.focus();
  });

  afterAll(() => {
    textArea.parentNode.removeChild(textArea);
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
          tag: '*',
          blockTag: null,
          selected: '',
          wrap: false,
        });

        expect(textArea.value).toEqual(`${initialValue}* `);
      });

      it('inserts the tag on a new line if the current one is not empty', () => {
        const initialValue = 'some text';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '*',
          blockTag: null,
          selected: '',
          wrap: false,
        });

        expect(textArea.value).toEqual(`${initialValue}\n* `);
      });

      it('inserts the tag on the same line if the current line only contains spaces', () => {
        const initialValue = '  ';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '*',
          blockTag: null,
          selected: '',
          wrap: false,
        });

        expect(textArea.value).toEqual(`${initialValue}* `);
      });

      it('inserts the tag on the same line if the current line only contains tabs', () => {
        const initialValue = '\t\t\t';

        textArea.value = initialValue;
        textArea.setSelectionRange(initialValue.length, initialValue.length);

        insertMarkdownText({
          textArea,
          text: textArea.value,
          tag: '*',
          blockTag: null,
          selected: '',
          wrap: false,
        });

        expect(textArea.value).toEqual(`${initialValue}* `);
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
    });

    describe('with selection', () => {
      const text = 'initial selected value';
      const selected = 'selected';
      beforeEach(() => {
        textArea.value = text;
        const selectedIndex = text.indexOf(selected);
        textArea.setSelectionRange(selectedIndex, selectedIndex + selected.length);
      });

      it('applies the tag to the selected value', () => {
        const selectedIndex = text.indexOf(selected);
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
          const selectedIndex = initialValue.indexOf(selected);
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
          const selectedIndex = initialValue.indexOf(expectedUrl);
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
      });
    });
  });

  describe('Ace Editor', () => {
    let editor;

    beforeEach(() => {
      editor = {
        getSelectionRange: () => ({
          start: 0,
          end: 0,
        }),
        getValue: () => 'this is text \n in two lines',
        insert: () => {},
        navigateLeft: () => {},
      };
    });

    it('uses ace editor insert text when editor is passed in', () => {
      jest.spyOn(editor, 'insert').mockReturnValue();

      insertMarkdownText({
        text: editor.getValue,
        tag: '*',
        blockTag: null,
        selected: '',
        wrap: false,
        editor,
      });

      expect(editor.insert).toHaveBeenCalled();
    });

    it('adds block tags on line above and below selection', () => {
      jest.spyOn(editor, 'insert').mockReturnValue();

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

      expect(editor.insert).toHaveBeenCalledWith(`***\n${selected}\n***`);
    });

    it('uses ace editor to navigate back tag length when nothing is selected', () => {
      jest.spyOn(editor, 'navigateLeft').mockReturnValue();

      insertMarkdownText({
        text: editor.getValue,
        tag: '*',
        blockTag: null,
        selected: '',
        wrap: true,
        editor,
      });

      expect(editor.navigateLeft).toHaveBeenCalledWith(1);
    });

    it('ace editor does not navigate back when there is selected text', () => {
      jest.spyOn(editor, 'navigateLeft').mockReturnValue();

      insertMarkdownText({
        text: editor.getValue,
        tag: '*',
        blockTag: null,
        selected: 'foobar',
        wrap: true,
        editor,
      });

      expect(editor.navigateLeft).not.toHaveBeenCalled();
    });
  });
});
