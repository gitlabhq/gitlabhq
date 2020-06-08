import CommentTypeToggle from '~/comment_type_toggle';
import DropLab from '~/droplab/drop_lab';
import InputSetter from '~/droplab/plugins/input_setter';

describe('CommentTypeToggle', () => {
  const testContext = {};

  describe('class constructor', () => {
    beforeEach(() => {
      testContext.dropdownTrigger = {};
      testContext.dropdownList = {};
      testContext.noteTypeInput = {};
      testContext.submitButton = {};
      testContext.closeButton = {};

      testContext.commentTypeToggle = new CommentTypeToggle({
        dropdownTrigger: testContext.dropdownTrigger,
        dropdownList: testContext.dropdownList,
        noteTypeInput: testContext.noteTypeInput,
        submitButton: testContext.submitButton,
        closeButton: testContext.closeButton,
      });
    });

    it('should set .dropdownTrigger', () => {
      expect(testContext.commentTypeToggle.dropdownTrigger).toBe(testContext.dropdownTrigger);
    });

    it('should set .dropdownList', () => {
      expect(testContext.commentTypeToggle.dropdownList).toBe(testContext.dropdownList);
    });

    it('should set .noteTypeInput', () => {
      expect(testContext.commentTypeToggle.noteTypeInput).toBe(testContext.noteTypeInput);
    });

    it('should set .submitButton', () => {
      expect(testContext.commentTypeToggle.submitButton).toBe(testContext.submitButton);
    });

    it('should set .closeButton', () => {
      expect(testContext.commentTypeToggle.closeButton).toBe(testContext.closeButton);
    });

    it('should set .reopenButton', () => {
      expect(testContext.commentTypeToggle.reopenButton).toBe(testContext.reopenButton);
    });
  });

  describe('initDroplab', () => {
    beforeEach(() => {
      testContext.commentTypeToggle = {
        dropdownTrigger: {},
        dropdownList: {},
        noteTypeInput: {},
        submitButton: {},
        closeButton: {},
        setConfig: () => {},
      };
      testContext.config = {};

      jest.spyOn(DropLab.prototype, 'init').mockImplementation();
      jest.spyOn(DropLab.prototype, 'constructor').mockImplementation();

      jest.spyOn(testContext.commentTypeToggle, 'setConfig').mockReturnValue(testContext.config);

      CommentTypeToggle.prototype.initDroplab.call(testContext.commentTypeToggle);
    });

    it('should instantiate a DropLab instance and set .droplab', () => {
      expect(testContext.commentTypeToggle.droplab instanceof DropLab).toBe(true);
    });

    it('should call .setConfig', () => {
      expect(testContext.commentTypeToggle.setConfig).toHaveBeenCalled();
    });

    it('should call DropLab.prototype.init', () => {
      expect(DropLab.prototype.init).toHaveBeenCalledWith(
        testContext.commentTypeToggle.dropdownTrigger,
        testContext.commentTypeToggle.dropdownList,
        [InputSetter],
        testContext.config,
      );
    });
  });

  describe('setConfig', () => {
    describe('if no .closeButton is provided', () => {
      beforeEach(() => {
        testContext.commentTypeToggle = {
          dropdownTrigger: {},
          dropdownList: {},
          noteTypeInput: {},
          submitButton: {},
          reopenButton: {},
        };

        testContext.setConfig = CommentTypeToggle.prototype.setConfig.call(
          testContext.commentTypeToggle,
        );
      });

      it('should not add .closeButton related InputSetter config', () => {
        expect(testContext.setConfig).toEqual({
          InputSetter: [
            {
              input: testContext.commentTypeToggle.noteTypeInput,
              valueAttribute: 'data-value',
            },
            {
              input: testContext.commentTypeToggle.submitButton,
              valueAttribute: 'data-submit-text',
            },
            {
              input: testContext.commentTypeToggle.reopenButton,
              valueAttribute: 'data-reopen-text',
            },
            {
              input: testContext.commentTypeToggle.reopenButton,
              valueAttribute: 'data-reopen-text',
              inputAttribute: 'data-alternative-text',
            },
          ],
        });
      });
    });

    describe('if no .reopenButton is provided', () => {
      beforeEach(() => {
        testContext.commentTypeToggle = {
          dropdownTrigger: {},
          dropdownList: {},
          noteTypeInput: {},
          submitButton: {},
          closeButton: {},
        };

        testContext.setConfig = CommentTypeToggle.prototype.setConfig.call(
          testContext.commentTypeToggle,
        );
      });

      it('should not add .reopenButton related InputSetter config', () => {
        expect(testContext.setConfig).toEqual({
          InputSetter: [
            {
              input: testContext.commentTypeToggle.noteTypeInput,
              valueAttribute: 'data-value',
            },
            {
              input: testContext.commentTypeToggle.submitButton,
              valueAttribute: 'data-submit-text',
            },
            {
              input: testContext.commentTypeToggle.closeButton,
              valueAttribute: 'data-close-text',
            },
            {
              input: testContext.commentTypeToggle.closeButton,
              valueAttribute: 'data-close-text',
              inputAttribute: 'data-alternative-text',
            },
          ],
        });
      });
    });
  });
});
