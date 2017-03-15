/* global DropLab */
/* global droplabInputSetter */

class CommentTypeToggle {
  constructor(trigger, list, input, button) {
    this.trigger = trigger;
    this.list = list;
    this.input = input;
    this.button = button;
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
      }],
    });
  }
}

export default CommentTypeToggle;
