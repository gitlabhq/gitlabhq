import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import syntaxHighlight from '~/syntax_highlight';

describe('Syntax Highlighter', () => {
  // We have to bind `document.querySelectorAll` to `document` to not mess up the fn's context
  describe.each`
    desc                | fn
    ${'jquery'}         | ${$}
    ${'vanilla all'}    | ${document.querySelectorAll.bind(document)}
    ${'vanilla single'} | ${document.querySelector.bind(document)}
  `('highlight using $desc syntax', ({ fn }) => {
    describe('on a js-syntax-highlight element', () => {
      beforeEach(() => {
        setHTMLFixture('<div class="js-syntax-highlight"></div>');
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('applies syntax highlighting', () => {
        syntaxHighlight(fn('.js-syntax-highlight'));

        expect(fn('.js-syntax-highlight')).toHaveClass('code-syntax-highlight-theme');
      });
    });

    describe('on a parent element', () => {
      beforeEach(() => {
        setHTMLFixture(
          '<div class="parent">\n  <div class="js-syntax-highlight"></div>\n  <div class="foo"></div>\n  <div class="js-syntax-highlight"></div>\n</div>',
        );
      });

      afterEach(() => {
        resetHTMLFixture();
      });

      it('applies highlighting to all applicable children', () => {
        syntaxHighlight(fn('.parent'));

        expect(fn('.parent')).not.toHaveClass('code-syntax-highlight-theme');
        expect(fn('.foo')).not.toHaveClass('code-syntax-highlight-theme');

        expect(document.querySelectorAll('.code-syntax-highlight-theme')).toHaveLength(2);
      });

      it('prevents an infinite loop when no matches exist', () => {
        setHTMLFixture('<div></div>');
        const highlight = () => syntaxHighlight(fn('div'));

        expect(highlight).not.toThrow();
      });
    });
  });
});
