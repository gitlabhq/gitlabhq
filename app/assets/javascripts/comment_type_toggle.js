import DropLab from './droplab/drop_lab';
import InputSetter from './droplab/plugins/input_setter';

class CommentTypeToggle {
  constructor(opts = {}) {
    this.dropdownTrigger = opts.dropdownTrigger;
    this.dropdownList = opts.dropdownList;
    this.noteTypeInput = opts.noteTypeInput;
    this.submitButton = opts.submitButton;
    this.closeButton = opts.closeButton;
    this.reopenButton = opts.reopenButton;
  }

  initDroplab() {
    this.droplab = new DropLab();

    const config = this.setConfig();

    this.droplab.init(this.dropdownTrigger, this.dropdownList, [InputSetter], config);
  }

  setConfig() {
    const config = {
      InputSetter: [{
        input: this.noteTypeInput,
        valueAttribute: 'data-value',
      },
      {
        input: this.submitButton,
        valueAttribute: 'data-submit-text',
      }],
    };

    if (this.closeButton) {
      config.InputSetter.push({
        input: this.closeButton,
        valueAttribute: 'data-close-text',
      }, {
        input: this.closeButton,
        valueAttribute: 'data-close-text',
        inputAttribute: 'data-alternative-text',
      });
    }

    if (this.reopenButton) {
      config.InputSetter.push({
        input: this.reopenButton,
        valueAttribute: 'data-reopen-text',
      }, {
        input: this.reopenButton,
        valueAttribute: 'data-reopen-text',
        inputAttribute: 'data-alternative-text',
      });
    }

    return config;
  }
}

export default CommentTypeToggle;
