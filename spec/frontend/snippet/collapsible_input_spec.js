import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import setupCollapsibleInputs from '~/snippet/collapsible_input';

describe('~/snippet/collapsible_input', () => {
  let formEl;
  let descriptionEl;
  let titleEl;
  let fooEl;

  beforeEach(() => {
    setHTMLFixture(`
      <form>
        <div class="js-collapsible-input js-title">
          <div class="js-collapsed !gl-hidden">
            <input type="text" />
          </div>
          <div class="js-expanded">
            <textarea>Hello World!</textarea>
          </div>
        </div>
        <div class="js-collapsible-input js-description">
          <div class="js-collapsed">
            <input type="text" />
          </div>
          <div class="js-expanded !gl-hidden">
            <textarea></textarea>
          </div>
        </div>
        <input type="text" class="js-foo" />
      </form>
    `);

    formEl = document.querySelector('form');
    titleEl = formEl.querySelector('.js-title');
    descriptionEl = formEl.querySelector('.js-description');
    fooEl = formEl.querySelector('.js-foo');

    setupCollapsibleInputs();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const findInput = (el) => el.querySelector('textarea,input');
  const findCollapsed = (el) => el.querySelector('.js-collapsed');
  const findExpanded = (el) => el.querySelector('.js-expanded');
  const findCollapsedInput = (el) => findInput(findCollapsed(el));
  const findExpandedInput = (el) => findInput(findExpanded(el));
  const focusIn = (target) => target.dispatchEvent(new Event('focusin', { bubbles: true }));
  const expectIsCollapsed = (el, isCollapsed) => {
    expect(findCollapsed(el).classList.contains('!gl-hidden')).toEqual(!isCollapsed);
    expect(findExpanded(el).classList.contains('!gl-hidden')).toEqual(isCollapsed);
  };

  describe('when collapsed', () => {
    it('is collapsed', () => {
      expectIsCollapsed(descriptionEl, true);
    });

    describe('when focused', () => {
      beforeEach(() => {
        focusIn(findCollapsedInput(descriptionEl));
      });

      it('is expanded', () => {
        expectIsCollapsed(descriptionEl, false);
      });

      describe.each`
        desc                           | value             | isCollapsed
        ${'is collapsed'}              | ${''}             | ${true}
        ${'stays open if given value'} | ${'Hello world!'} | ${false}
      `('when loses focus', ({ desc, value, isCollapsed }) => {
        it(`${desc}`, () => {
          findExpandedInput(descriptionEl).value = value;
          focusIn(fooEl);

          expectIsCollapsed(descriptionEl, isCollapsed);
        });
      });
    });
  });

  describe('when expanded and has value', () => {
    it('does not collapse, when focusing out', () => {
      expectIsCollapsed(titleEl, false);

      focusIn(fooEl);

      expectIsCollapsed(titleEl, false);
    });

    describe('and loses value', () => {
      beforeEach(() => {
        findExpandedInput(titleEl).value = '';
      });

      it('collapses, when focusing out', () => {
        expectIsCollapsed(titleEl, false);

        focusIn(fooEl);

        expectIsCollapsed(titleEl, true);
      });
    });
  });
});
