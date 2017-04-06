import DropLab from '~/droplab/drop_lab';
import InputSetter from '~/droplab/plugins/input_setter';

class CommentTypeToggle {
  constructor(dropdownTrigger, dropdownList, noteTypeInput, submitButton, closeButton) {
    this.dropdownTrigger = dropdownTrigger;
    this.dropdownList = dropdownList;
    this.noteTypeInput = noteTypeInput;
    this.submitButton = submitButton;
    this.closeButton = closeButton;
  }

  initDroplab() {
    this.droplab = new DropLab();

    const inputSetterConfig = [{
      input: this.noteTypeInput,
      valueAttribute: 'data-value',
    },
    {
      input: this.submitButton,
      valueAttribute: 'data-button-text',
    }];
    if (this.closeButton) {
      inputSetterConfig.push({
        input: this.closeButton,
        valueAttribute: 'data-secondary-button-text',
      }, {
        input: this.closeButton,
        valueAttribute: 'data-secondary-button-text',
        inputAttribute: 'data-alternative-text',
      });
    }

    this.droplab.init(this.dropdownTrigger, this.dropdownList, [InputSetter], {
      InputSetter: inputSetterConfig,
    });
  }
}

export default CommentTypeToggle;
