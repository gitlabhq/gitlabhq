const createTestElement = () => {
  const element = document.createElement('div');

  element.textContent = 'Hello World!';

  return element;
};

describe('DOM patch for getClientRects', () => {
  let origHtml;
  let el;

  beforeEach(() => {
    origHtml = document.body.innerHTML;
    el = createTestElement();
  });

  afterEach(() => {
    document.body.innerHTML = origHtml;
  });

  describe('toBeVisible matcher', () => {
    describe('when not attached to document', () => {
      it('does not match', () => {
        expect(el).not.toBeVisible();
      });
    });

    describe('when attached to document', () => {
      beforeEach(() => {
        document.body.appendChild(el);
      });

      it('matches', () => {
        expect(el).toBeVisible();
      });
    });

    describe('with parent and attached to document', () => {
      let parentEl;

      beforeEach(() => {
        parentEl = createTestElement();
        parentEl.appendChild(el);
        document.body.appendChild(parentEl);
      });

      it('matches', () => {
        expect(el).toBeVisible();
      });

      describe.each`
        style
        ${{ display: 'none' }}
        ${{ visibility: 'hidden' }}
      `('with style $style', ({ style }) => {
        it('does not match when applied to element', () => {
          Object.assign(el.style, style);

          expect(el).not.toBeVisible();
        });

        it('does not match when applied to parent', () => {
          Object.assign(parentEl.style, style);

          expect(el).not.toBeVisible();
        });
      });
    });
  });
});
