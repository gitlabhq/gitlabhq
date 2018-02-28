
const HIDDEN_VALUE_TEXT = '******';

export default class ProjectVariables {
  constructor() {
    this.$revealBtn = $('.js-btn-toggle-reveal-values');
    this.$revealBtn.on('click', this.toggleRevealState.bind(this));
  }

  toggleRevealState(e) {
    e.preventDefault();

    const oldStatus = this.$revealBtn.attr('data-status');
    let newStatus = 'hidden';
    let newAction = 'Reveal Values';

    if (oldStatus === 'hidden') {
      newStatus = 'revealed';
      newAction = 'Hide Values';
    }

    this.$revealBtn.attr('data-status', newStatus);

    const $variables = $('.variable-value');

    $variables.each((_, variable) => {
      const $variable = $(variable);
      let newText = HIDDEN_VALUE_TEXT;

      if (newStatus === 'revealed') {
        newText = $variable.attr('data-value');
      }

      $variable.text(newText);
    });

    this.$revealBtn.text(newAction);
  }
}
