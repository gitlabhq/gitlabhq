import autosize from 'autosize';
import $ from 'jquery';
import GLForm from '~/gl_form';
import '~/lib/utils/text_utility';
import '~/lib/utils/common_utils';

describe('GLForm', () => {
  const testContext = {};

  describe('when instantiated', () => {
    beforeEach((done) => {
      window.gl = window.gl || {};

      testContext.form = $('<form class="gfm-form"><textarea class="js-gfm-input"></form>');
      testContext.textarea = testContext.form.find('textarea');
      jest.spyOn($.prototype, 'off').mockReturnValue(testContext.textarea);
      jest.spyOn($.prototype, 'on').mockReturnValue(testContext.textarea);
      jest.spyOn($.prototype, 'css').mockImplementation(() => {});

      testContext.glForm = new GLForm(testContext.form, false);

      setImmediate(() => {
        $.prototype.off.mockClear();
        $.prototype.on.mockClear();
        $.prototype.css.mockClear();
        done();
      });
    });

    describe('setupAutosize', () => {
      beforeEach((done) => {
        testContext.glForm.setupAutosize();

        setImmediate(() => {
          done();
        });
      });

      it('should register an autosize event handler on the textarea', () => {
        expect($.prototype.off).toHaveBeenCalledWith('autosize:resized');
        expect($.prototype.on).toHaveBeenCalledWith('autosize:resized', expect.any(Function));
      });

      it('should register a mouseup event handler on the textarea', () => {
        expect($.prototype.off).toHaveBeenCalledWith('mouseup.autosize');
        expect($.prototype.on).toHaveBeenCalledWith('mouseup.autosize', expect.any(Function));
      });

      it('should set the resize css property to vertical', () => {
        jest.runOnlyPendingTimers();
        expect($.prototype.css).toHaveBeenCalledWith('resize', 'vertical');
      });
    });

    describe('setHeightData', () => {
      beforeEach(() => {
        jest.spyOn($.prototype, 'data').mockImplementation(() => {});
        jest.spyOn($.prototype, 'outerHeight').mockReturnValue(200);
        testContext.glForm.setHeightData();
      });

      it('should set the height data attribute', () => {
        expect($.prototype.data).toHaveBeenCalledWith('height', 200);
      });

      it('should call outerHeight', () => {
        expect($.prototype.outerHeight).toHaveBeenCalled();
      });
    });

    describe('destroyAutosize', () => {
      describe('when called', () => {
        beforeEach(() => {
          jest.spyOn($.prototype, 'data').mockImplementation(() => {});
          jest.spyOn($.prototype, 'outerHeight').mockReturnValue(200);
          window.outerHeight = () => 400;
          jest.spyOn(autosize, 'destroy').mockImplementation(() => {});

          testContext.glForm.destroyAutosize();
        });

        it('should call outerHeight', () => {
          expect($.prototype.outerHeight).toHaveBeenCalled();
        });

        it('should get data-height attribute', () => {
          expect($.prototype.data).toHaveBeenCalledWith('height');
        });

        it('should call autosize destroy', () => {
          expect(autosize.destroy).toHaveBeenCalledWith(testContext.textarea);
        });

        it('should set the data-height attribute', () => {
          expect($.prototype.data).toHaveBeenCalledWith('height', 200);
        });

        it('should set the outerHeight', () => {
          expect($.prototype.outerHeight).toHaveBeenCalledWith(200);
        });

        it('should set the css', () => {
          expect($.prototype.css).toHaveBeenCalledWith('max-height', window.outerHeight);
        });
      });

      it('should return undefined if the data-height equals the outerHeight', () => {
        jest.spyOn($.prototype, 'outerHeight').mockReturnValue(200);
        jest.spyOn($.prototype, 'data').mockReturnValue(200);
        jest.spyOn(autosize, 'destroy').mockImplementation(() => {});

        expect(testContext.glForm.destroyAutosize()).toBeUndefined();
        expect(autosize.destroy).not.toHaveBeenCalled();
      });
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
