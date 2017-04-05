import DropLab from '@gitlab-org/droplab';
import InputSetter from '@gitlab-org/droplab/dist/plugins/InputSetter';

class CommentTypeToggle {
  constructor(trigger, list, input, button, secondaryButton) {
    this.trigger = trigger;
    this.list = list;
    this.input = input;
    this.button = button;
    this.secondaryButton = secondaryButton;
  }

  initDroplab() {
    this.droplab = new DropLab();
    this.droplab.init(this.trigger, this.list, [InputSetter], {
      InputSetter: [{
        input: this.input,
        valueAttribute: 'data-value',
      },
      {
        input: this.button,
        valueAttribute: 'data-button-text',
      },
      {
        input: this.secondaryButton,
        valueAttribute: 'data-secondary-button-text',
      }],
    });
  }
}

export default CommentTypeToggle;
