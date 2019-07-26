import IndentHelper from '~/helpers/indent_helper';

function createMockTextarea() {
  const el = document.createElement('textarea');
  el.setCursor = pos => el.setSelectionRange(pos, pos);
  el.setCursorToEnd = () => el.setCursor(el.value.length);
  el.selection = () => [el.selectionStart, el.selectionEnd];
  el.cursor = () => {
    const [start, end] = el.selection();
    return start === end ? start : undefined;
  };
  return el;
}

describe('indent_helper', () => {
  let element;
  let ih;

  beforeEach(() => {
    element = createMockTextarea();
    ih = new IndentHelper(element);
  });

  describe('indents', () => {
    describe('a single line', () => {
      it('when on an empty line; and cursor follows', () => {
        element.value = '';
        ih.indent();
        expect(element.value).toBe('    ');
        expect(element.cursor()).toBe(4);
        ih.indent();
        expect(element.value).toBe('        ');
        expect(element.cursor()).toBe(8);
      });

      it('when at the start of a line; and cursor stays at start', () => {
        element.value = 'foobar';
        element.setCursor(0);
        ih.indent();
        expect(element.value).toBe('    foobar');
        expect(element.cursor()).toBe(4);
      });

      it('when the cursor is in the middle; and cursor follows', () => {
        element.value = 'foobar';
        element.setCursor(3);
        ih.indent();
        expect(element.value).toBe('    foobar');
        expect(element.cursor()).toBe(7);
      });
    });

    describe('several lines', () => {
      it('when everything is selected; and everything remains selected', () => {
        element.value = 'foo\nbar\nbaz';
        element.setSelectionRange(0, 11);
        ih.indent();
        expect(element.value).toBe('    foo\n    bar\n    baz');
        expect(element.selection()).toEqual([0, 23]);
      });

      it('when all lines are partially selected; and the selection adapts', () => {
        element.value = 'foo\nbar\nbaz';
        element.setSelectionRange(2, 9);
        ih.indent();
        expect(element.value).toBe('    foo\n    bar\n    baz');
        expect(element.selection()).toEqual([6, 21]);
      });

      it('when some lines are entirely selected; and entire lines remain selected', () => {
        element.value = 'foo\nbar\nbaz';
        element.setSelectionRange(4, 11);
        ih.indent();
        expect(element.value).toBe('foo\n    bar\n    baz');
        expect(element.selection()).toEqual([4, 19]);
      });

      it('when some lines are partially selected; and the selection adapts', () => {
        element.value = 'foo\nbar\nbaz';
        element.setSelectionRange(5, 9);
        ih.indent();
        expect(element.value).toBe('foo\n    bar\n    baz');
        expect(element.selection()).toEqual([5 + 4, 9 + 2 * 4]);
      });

      it('having different indentation when some lines are entirely selected; and entire lines remain selected', () => {
        element.value = '    foo\nbar\n    baz';
        element.setSelectionRange(8, 19);
        ih.indent();
        expect(element.value).toBe('    foo\n    bar\n        baz');
        expect(element.selection()).toEqual([8, 27]);
      });

      it('having different indentation when some lines are partially selected; and the selection adapts', () => {
        element.value = '    foo\nbar\n    baz';
        element.setSelectionRange(9, 14);
        ih.indent();
        expect(element.value).toBe('    foo\n    bar\n        baz');
        expect(element.selection()).toEqual([13, 22]);
      });
    });
  });

  describe('unindents', () => {
    describe('a single line', () => {
      it('but does nothing if there is not indent', () => {
        element.value = 'foobar';
        element.setCursor(2);
        ih.unindent();
        expect(element.value).toBe('foobar');
        expect(element.cursor()).toBe(2);
      });

      it('but does nothing if there is a partial indent', () => {
        element.value = '  foobar';
        element.setCursor(1);
        ih.unindent();
        expect(element.value).toBe('  foobar');
        expect(element.cursor()).toBe(1);
      });

      it('when the cursor is in the line text; cursor follows', () => {
        element.value = '    foobar';
        element.setCursor(6);
        ih.unindent();
        expect(element.value).toBe('foobar');
        expect(element.cursor()).toBe(2);
      });

      it('when the cursor is in the indent; and cursor goes to start', () => {
        element.value = '    foobar';
        element.setCursor(2);
        ih.unindent();
        expect(element.value).toBe('foobar');
        expect(element.cursor()).toBe(0);
      });

      it('when the cursor is at line start; and cursor stays at start', () => {
        element.value = '    foobar';
        element.setCursor(0);
        ih.unindent();
        expect(element.value).toBe('foobar');
        expect(element.cursor()).toBe(0);
      });

      it('when a selection includes part of the indent and text', () => {
        element.value = '    foobar';
        element.setSelectionRange(2, 8);
        ih.unindent();
        expect(element.value).toBe('foobar');
        expect(element.selection()).toEqual([0, 4]);
      });

      it('when a selection includes part of the indent only', () => {
        element.value = '    foobar';
        element.setSelectionRange(0, 4);
        ih.unindent();
        expect(element.value).toBe('foobar');
        expect(element.cursor()).toBe(0);

        element.value = '    foobar';
        element.setSelectionRange(1, 3);
        ih.unindent();
        expect(element.value).toBe('foobar');
        expect(element.cursor()).toBe(0);
      });
    });

    describe('several lines', () => {
      it('when everything is selected', () => {
        element.value = '    foo\n        bar\n    baz';
        element.setSelectionRange(0, 27);
        ih.unindent();
        expect(element.value).toBe('foo\n    bar\nbaz');
        expect(element.selection()).toEqual([0, 15]);
      });

      it('when all lines are partially selected', () => {
        element.value = '    foo\n        bar\n    baz';
        element.setSelectionRange(5, 26);
        ih.unindent();
        expect(element.value).toBe('foo\n    bar\nbaz');
        expect(element.selection()).toEqual([1, 14]);
      });

      it('when all lines are entirely selected', () => {
        element.value = '    foo\n        bar\n    baz';
        element.setSelectionRange(8, 27);
        ih.unindent();
        expect(element.value).toBe('    foo\n    bar\nbaz');
        expect(element.selection()).toEqual([8, 19]);
      });

      it('when some lines are entirely selected', () => {
        element.value = '    foo\n        bar\n    baz';
        element.setSelectionRange(8, 27);
        ih.unindent();
        expect(element.value).toBe('    foo\n    bar\nbaz');
        expect(element.selection()).toEqual([8, 19]);
      });

      it('when some lines are partially selected', () => {
        element.value = '    foo\n        bar\n    baz';
        element.setSelectionRange(17, 26);
        ih.unindent();
        expect(element.value).toBe('    foo\n    bar\nbaz');
        expect(element.selection()).toEqual([13, 18]);
      });

      it('when some lines are partially selected within their indents', () => {
        element.value = '    foo\n        bar\n    baz';
        element.setSelectionRange(10, 22);
        ih.unindent();
        expect(element.value).toBe('    foo\n    bar\nbaz');
        expect(element.selection()).toEqual([8, 16]);
      });
    });
  });

  describe('newline', () => {
    describe('on a single line', () => {
      it('auto-indents the new line', () => {
        element.value = 'foo\n bar\n    baz\n        qux';

        element.setCursor(3);
        ih.newline();
        expect(element.value).toBe('foo\n\n bar\n    baz\n        qux');
        expect(element.cursor()).toBe(4);

        element.setCursor(9);
        ih.newline();
        expect(element.value).toBe('foo\n\n bar\n \n    baz\n        qux');
        expect(element.cursor()).toBe(11);

        element.setCursor(19);
        ih.newline();
        expect(element.value).toBe('foo\n\n bar\n \n    baz\n    \n        qux');
        expect(element.cursor()).toBe(24);

        element.setCursor(36);
        ih.newline();
        expect(element.value).toBe('foo\n\n bar\n \n    baz\n    \n        qux\n        ');
        expect(element.cursor()).toBe(45);
      });

      it('splits a line and auto-indents', () => {
        element.value = '    foobar';
        element.setCursor(7);
        ih.newline();
        expect(element.value).toBe('    foo\n    bar');
        expect(element.cursor()).toBe(12);
      });

      it('replaces selection with an indented newline', () => {
        element.value = '    foobarbaz';
        element.setSelectionRange(7, 10);
        ih.newline();
        expect(element.value).toBe('    foo\n    baz');
        expect(element.cursor()).toBe(12);
      });
    });

    it('on several lines.replaces selection with indented newline', () => {
      element.value = '  foo\n    bar\n  baz';
      element.setSelectionRange(4, 17);
      ih.newline();
      expect(element.value).toBe('  fo\n  az');
      expect(element.cursor()).toBe(7);
    });
  });

  describe('backspace', () => {
    let event;

    // This suite tests only the special indent-removing behaviour of the
    // backspace() method, since non-special cases are handled natively as a
    // backspace keypress.

    beforeEach(() => {
      event = { preventDefault: jest.fn() };
    });

    describe('on a single line', () => {
      it('does nothing special if in the line text', () => {
        element.value = '    foobar';
        element.setCursor(7);
        ih.backspace(event);
        expect(event.preventDefault).not.toHaveBeenCalled();
      });

      it('does nothing special if after a non-leading indent', () => {
        element.value = '    foo    bar';
        element.setCursor(11);
        ih.backspace(event);
        expect(event.preventDefault).not.toHaveBeenCalled();
      });

      it('deletes one leading indent', () => {
        element.value = '        foo';
        element.setCursor(8);
        ih.backspace(event);
        expect(event.preventDefault).toHaveBeenCalled();
        expect(element.value).toBe('    foo');
        expect(element.cursor()).toBe(4);
      });

      it('does nothing if cursor is inside the leading indent', () => {
        element.value = '        foo';
        element.setCursor(4);
        ih.backspace(event);
        expect(event.preventDefault).not.toHaveBeenCalled();
      });

      it('does nothing if cursor is at the start of the line', () => {
        element.value = '    foo';
        element.setCursor(0);
        ih.backspace(event);
        expect(event.preventDefault).not.toHaveBeenCalled();
      });

      it('deletes one partial indent', () => {
        element.value = '      foo';
        element.setCursor(6);
        ih.backspace(event);
        expect(event.preventDefault).toHaveBeenCalled();
        expect(element.value).toBe('    foo');
        expect(element.cursor()).toBe(4);
      });

      it('deletes indents sequentially', () => {
        element.value = '          foo';
        element.setCursor(10);
        ih.backspace(event);
        ih.backspace(event);
        ih.backspace(event);
        expect(event.preventDefault).toHaveBeenCalled();
        expect(element.value).toBe('foo');
        expect(element.cursor()).toBe(0);
      });
    });

    describe('on several lines', () => {
      it('deletes indent only on its own line', () => {
        element.value = '    foo\n        bar\n    baz';
        element.setCursor(16);
        ih.backspace(event);
        expect(event.preventDefault).toHaveBeenCalled();
        expect(element.value).toBe('    foo\n    bar\n    baz');
        expect(element.cursor()).toBe(12);
      });

      it('has no special behaviour with any range selection', () => {
        const text = '  foo\n    bar\n  baz';
        for (let start = 0; start < text.length; start += 1) {
          for (let end = start + 1; end < text.length; end += 1) {
            element.value = text;
            element.setSelectionRange(start, end);
            ih.backspace(event);
            expect(event.preventDefault).not.toHaveBeenCalled();

            // Ensure that the backspace() method doesn't change state
            // In reality, these two statements won't hold because the browser
            // will natively process the backspace event.
            expect(element.value).toBe(text);
            expect(element.selection()).toEqual([start, end]);
          }
        }
      });
    });
  });
});
