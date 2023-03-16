import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import syntaxHighlight from '~/syntax_highlight';

describe('Syntax Highlighter', () => {
  const stubUserColorScheme = (value) => {
    window.gon.user_color_scheme = value;
  };

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
        stubUserColorScheme('monokai');
        syntaxHighlight(fn('.js-syntax-highlight'));

        expect(fn('.js-syntax-highlight')).toHaveClass('monokai');
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
        stubUserColorScheme('monokai');
        syntaxHighlight(fn('.parent'));

        expect(fn('.parent')).not.toHaveClass('monokai');
        expect(fn('.foo')).not.toHaveClass('monokai');

        expect(document.querySelectorAll('.monokai').length).toBe(2);
      });

      it('prevents an infinite loop when no matches exist', () => {
        setHTMLFixture('<div></div>');
        const highlight = () => syntaxHighlight(fn('div'));

        expect(highlight).not.toThrow();
      });
    });
  });
});
