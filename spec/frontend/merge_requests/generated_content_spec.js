import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

import { MergeRequestGeneratedContent } from '~/merge_requests/generated_content';

function findWarningElement() {
  return document.querySelector('.js-ai-description-warning');
}

function findCloseButton() {
  return findWarningElement()?.querySelector('.js-close-btn');
}

function findApprovalButton() {
  return findWarningElement()?.querySelector('.js-ai-override-description');
}

function findCancelButton() {
  return findWarningElement()?.querySelector('.js-cancel-btn');
}

function clickButton(button) {
  button.dispatchEvent(new Event('click'));
}

describe('MergeRequestGeneratedContent', () => {
  const warningDOM = `

<div class="js-ai-description-warning hidden">
  <button class="js-close-btn">X</button>
  <button class="js-ai-override-description">Do AI</button>
  <button class="js-cancel-btn">Cancel</button>
</div>

`;

  describe('class basics', () => {
    let gen;

    beforeEach(() => {
      gen = new MergeRequestGeneratedContent();
    });

    it.each`
      description                        | property
      ${'with no editor'}                | ${'hasEditor'}
      ${'with no warning'}               | ${'hasWarning'}
      ${'unable to replace the content'} | ${'canReplaceContent'}
    `('begins $description', ({ property }) => {
      expect(gen[property]).toBe(false);
    });
  });

  describe('the internal editor representation', () => {
    let gen;

    it('accepts an editor during construction', () => {
      gen = new MergeRequestGeneratedContent({ editor: {} });

      expect(gen.hasEditor).toBe(true);
    });

    it('allows adding an editor through a public API after construction', () => {
      gen = new MergeRequestGeneratedContent();

      expect(gen.hasEditor).toBe(false);

      gen.setEditor({});

      expect(gen.hasEditor).toBe(true);
    });
  });

  describe('generated content', () => {
    let gen;

    beforeEach(() => {
      gen = new MergeRequestGeneratedContent();
    });

    it('can be provided to the instance through a public API', () => {
      expect(gen.generatedContent).toBe(null);

      gen.setGeneratedContent('generated content');

      expect(gen.generatedContent).toBe('generated content');
    });

    it('can be cleared from the instance through a public API', () => {
      gen.setGeneratedContent('generated content');

      expect(gen.generatedContent).toBe('generated content');

      gen.clearGeneratedContent();

      expect(gen.generatedContent).toBe(null);
    });
  });

  describe('warning element', () => {
    let gen;

    afterEach(() => {
      resetHTMLFixture();
    });

    it.each`
      presence    | withFixture
      ${'is'}     | ${true}
      ${'is not'} | ${false}
    `('`.hasWarning` is $withFixture when the element $presence in the DOM', ({ withFixture }) => {
      if (withFixture) {
        setHTMLFixture(warningDOM);
      }

      gen = new MergeRequestGeneratedContent();

      expect(gen.hasWarning).toBe(withFixture);
    });
  });

  describe('special cases', () => {
    it.each`
      description                                                                     | value    | props
      ${'there is no internal editor representation, and no generated content'}       | ${false} | ${{}}
      ${'there is an internal editor representation, but no generated content'}       | ${false} | ${{ editor: {} }}
      ${'there is no internal editor representation, but there is generated content'} | ${false} | ${{ content: 'generated content' }}
      ${'there is an internal editor representation, and there is generated content'} | ${true}  | ${{ editor: {}, content: 'generated content' }}
    `('`.canReplaceContent` is $value when $description', ({ value, props }) => {
      const gen = new MergeRequestGeneratedContent();

      if (props.editor) {
        gen.setEditor(props.editor);
      }
      if (props.content) {
        gen.setGeneratedContent(props.content);
      }

      expect(gen.canReplaceContent).toBe(value);
    });
  });

  describe('behaviors', () => {
    describe('UI', () => {
      describe('warning element', () => {
        let gen;

        beforeEach(() => {
          setHTMLFixture(warningDOM);
          gen = new MergeRequestGeneratedContent({ editor: {} });

          gen.setGeneratedContent('generated content');
        });

        describe('#showWarning', () => {
          it("shows the warning if it exists in the DOM and if it's possible to replace the description", () => {
            gen.showWarning();

            expect(findWarningElement().classList.contains('hidden')).toBe(false);
          });

          it("does nothing if the warning doesn't exist or if it's not possible to replace the description", () => {
            gen.setEditor(null);

            gen.showWarning();

            expect(findWarningElement().classList.contains('hidden')).toBe(true);

            gen.setEditor({});
            gen.setGeneratedContent(null);

            gen.showWarning();

            expect(findWarningElement().classList.contains('hidden')).toBe(true);

            resetHTMLFixture();
            gen = new MergeRequestGeneratedContent({ editor: {} });
            gen.setGeneratedContent('generated content');

            expect(() => gen.showWarning()).not.toThrow();
            expect(findWarningElement()).toBe(null);
          });
        });

        describe('#hideWarning', () => {
          it('hides the warning', () => {
            findWarningElement().classList.remove('hidden');

            gen.hideWarning();

            expect(findWarningElement().classList.contains('hidden')).toBe(true);
          });

          it("does nothing if there's no warning element", () => {
            resetHTMLFixture();
            gen = new MergeRequestGeneratedContent();

            expect(() => gen.hideWarning()).not.toThrow();
            expect(findWarningElement()).toBe(null);
          });
        });
      });
    });

    describe('content', () => {
      const editor = {};
      let gen;

      beforeEach(() => {
        editor.setValue = jest.fn();
        gen = new MergeRequestGeneratedContent({ editor });
      });

      describe('#replaceDescription', () => {
        it("sets the instance's generated content value to the internal representation of the editor", () => {
          gen.setGeneratedContent('generated content');

          gen.replaceDescription();

          expect(editor.setValue).toHaveBeenCalledWith('generated content');
        });

        it("does nothing if there's no editor or no generated content", () => {
          // Starts with editor, but no content
          gen.replaceDescription();

          expect(editor.setValue).not.toHaveBeenCalled();

          gen.setGeneratedContent('generated content');
          gen.setEditor(null);

          gen.replaceDescription();

          expect(editor.setValue).not.toHaveBeenCalled();
        });

        it("clears the generated content so the warning can't be re-shown with stale content", () => {
          gen.setGeneratedContent('generated content');

          gen.replaceDescription();

          expect(editor.setValue).toHaveBeenCalledWith('generated content');
          expect(gen.hasEditor).toBe(true);
          expect(gen.canReplaceContent).toBe(false);
          expect(gen.generatedContent).toBe(null);
        });
      });
    });
  });

  describe('events', () => {
    describe('UI clicks', () => {
      const editor = {};
      let gen;

      beforeEach(() => {
        setHTMLFixture(warningDOM);
        editor.setValue = jest.fn();
        gen = new MergeRequestGeneratedContent({ editor });

        gen.setGeneratedContent('generated content');
      });

      describe('banner close button', () => {
        it('hides the warning element', () => {
          const close = findCloseButton();

          gen.showWarning();

          expect(findWarningElement().classList.contains('hidden')).toBe(false);

          clickButton(close);

          expect(findWarningElement().classList.contains('hidden')).toBe(true);
        });
      });

      describe('banner approval button', () => {
        it('sends the generated content to the editor, clears the internal generated content, and hides the warning', () => {
          const approve = findApprovalButton();

          gen.showWarning();

          expect(findWarningElement().classList.contains('hidden')).toBe(false);
          expect(gen.generatedContent).toBe('generated content');
          expect(editor.setValue).not.toHaveBeenCalled();

          clickButton(approve);

          expect(findWarningElement().classList.contains('hidden')).toBe(true);
          expect(gen.generatedContent).toBe(null);
          expect(editor.setValue).toHaveBeenCalledWith('generated content');
        });
      });

      describe('banner cancel button', () => {
        it('hides the warning element', () => {
          const cancel = findCancelButton();

          gen.showWarning();

          expect(findWarningElement().classList.contains('hidden')).toBe(false);

          clickButton(cancel);

          expect(findWarningElement().classList.contains('hidden')).toBe(true);
        });
      });
    });
  });
});
