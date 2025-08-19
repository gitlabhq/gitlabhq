import $ from 'jquery';
import GLForm from '~/gl_form';
import '~/lib/utils/text_utility';
import '~/lib/utils/common_utils';

describe('GLForm', () => {
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

        testContext.form = $('<form class="gfm-form"><textarea class="js-gfm-input"></form>');
        testContext.textarea = testContext.form.find('textarea');
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

      testContext.form = $('<form class="gfm-form"><textarea class="js-gfm-input"></form>');
      testContext.textarea = testContext.form.find('textarea');
      jest.spyOn($.prototype, 'off').mockReturnValue(testContext.textarea);
      jest.spyOn($.prototype, 'on').mockReturnValue(testContext.textarea);
      jest.spyOn($.prototype, 'css').mockImplementation(() => {});

      testContext.glForm = new GLForm(testContext.form, false);
    });

    describe('autofocus', () => {
      it('focus the textarea when autofocus is true', () => {
        testContext.textarea.data('autofocus', true);
        jest.spyOn($.prototype, 'focus');

        testContext.glForm = new GLForm(testContext.form, false);

        expect($.prototype.focus).toHaveBeenCalled();
      });

      it("doesn't focus the textarea when autofocus is false", () => {
        testContext.textarea.data('autofocus', false);
        jest.spyOn($.prototype, 'focus');

        testContext.glForm = new GLForm(testContext.form, false);

        expect($.prototype.focus).not.toHaveBeenCalled();
      });
    });

    describe('supportsQuickActions', () => {
      it('should return false if textarea does not support quick actions', () => {
        const glForm = new GLForm(testContext.form, false);

        expect(glForm.supportsQuickActions).toEqual(false);
      });

      it('should return true if textarea supports quick actions', () => {
        testContext.textarea.attr('data-supports-quick-actions', true);

        const glForm = new GLForm(testContext.form, false);

        expect(glForm.supportsQuickActions).toEqual(true);
      });
    });
  });
});
