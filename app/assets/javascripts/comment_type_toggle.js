/* global DropLab */
/* global droplabInputSetter */

class CommentTypeToggle {
  constructor(trigger, list, input, button, secondaryButton) {
    this.trigger = trigger;
    this.list = list;
    this.input = input;
    this.button = button;
    this.secondaryButton = secondaryButton;
    console.log(secondaryButton)
  }

  initDroplab() {
    this.droplab = new DropLab();
    this.droplab.addHook(this.trigger, this.list, [droplabInputSetter], {
      droplabInputSetter: [{
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
