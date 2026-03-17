import GLForm from '~/gl_form';
import '~/lib/utils/text_utility';
import '~/lib/utils/common_utils';

describe('GLForm', () => {
  const createFormElement = (html) => {
    const container = document.createElement('div');
    container.innerHTML = html;
    return container.firstElementChild;
  };

  const testContext = {};
  const mockGl = {
    GfmAutoComplete: {
      dataSources: {
        commands: '/group/projects/-/autocomplete_sources/commands',
      },
    },
  };

  describe('Setting up GfmAutoComplete', () => {
    describe('setupForm', () => {
      let setupFormSpy;

      beforeEach(() => {
        setupFormSpy = jest.spyOn(GLForm.prototype, 'setupForm');

        testContext.form = createFormElement(
          '<form class="gfm-form"><textarea class="js-gfm-input"></textarea></form>',
        );
        testContext.textarea = testContext.form.querySelector('textarea');
      });

      it('should be called with the global data source `windows.gl`', () => {
        window.gl = { ...mockGl };
        testContext.glForm = new GLForm(testContext.form, {}, false);

        expect(setupFormSpy).toHaveBeenCalledTimes(1);
        expect(setupFormSpy).toHaveBeenCalledWith(window.gl.GfmAutoComplete.dataSources, false);
      });

      it('should be called with the provided custom data source', () => {
        window.gl = { ...mockGl };

        const customDataSources = {
          foobar: '/group/projects/-/autocomplete_sources/foobar',
        };

        testContext.glForm = new GLForm(testContext.form, {}, false, customDataSources);

        expect(setupFormSpy).toHaveBeenCalledTimes(1);
        expect(setupFormSpy).toHaveBeenCalledWith(customDataSources, false);
      });
    });
  });

  describe('when instantiated', () => {
    beforeEach(() => {
      window.gl = window.gl || {};

      testContext.form = createFormElement(
        '<form class="gfm-form"><textarea class="js-gfm-input"></textarea></form>',
      );
      testContext.textarea = testContext.form.querySelector('textarea');

      testContext.glForm = new GLForm(testContext.form, false);
    });

    describe('autofocus', () => {
      it('focus the textarea when autofocus is true', () => {
        testContext.textarea.dataset.autofocus = 'true';
        const focusSpy = jest.spyOn(testContext.textarea, 'focus');

        testContext.glForm = new GLForm(testContext.form, false);

        expect(focusSpy).toHaveBeenCalled();
      });

      it("doesn't focus the textarea when autofocus is false", () => {
        testContext.textarea.dataset.autofocus = 'false';
        const focusSpy = jest.spyOn(testContext.textarea, 'focus');

        testContext.glForm = new GLForm(testContext.form, false);

        expect(focusSpy).not.toHaveBeenCalled();
      });
    });

    describe('supportsQuickActions', () => {
      it('should return false if textarea does not support quick actions', () => {
        const glForm = new GLForm(testContext.form, false);

        expect(glForm.supportsQuickActions).toEqual(false);
      });

      it('should return true if textarea supports quick actions', () => {
        testContext.textarea.dataset.supportsQuickActions = 'true';

        const glForm = new GLForm(testContext.form, false);

        expect(glForm.supportsQuickActions).toEqual(true);
      });
    });
  });
});
