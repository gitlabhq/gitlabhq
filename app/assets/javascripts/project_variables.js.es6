/* eslint-disable */
((global) => {
  const HIDDEN_VALUE_TEXT = '******';

  class ProjectVariables {
    constructor() {
      this.$reveal = $('.js-btn-toggle-reveal-values');

      this.$reveal.on('click', this.toggleRevealState.bind(this));
    }

    toggleRevealState(event) {
      event.preventDefault();

      const $btn = $(event.currentTarget);
      const oldStatus = $btn.attr('data-status');

      if (oldStatus == 'hidden') {
        [newStatus, newAction] = ['revealed', 'Hide Values'];
      } else {
        [newStatus, newAction] = ['hidden', 'Reveal Values'];
      }

      $btn.attr('data-status', newStatus);

      let $variables = $('.variable-value');

      $variables.each(function (_, variable) {
        let $variable = $(variable);
        let newText = HIDDEN_VALUE_TEXT;

        if (newStatus == 'revealed') {
          newText = $variable.attr('data-value');
        }

        $variable.text(newText);
      });

      $btn.text(newAction);
    }
  }

  global.ProjectVariables = ProjectVariables;
})(window.gl || (window.gl = {}));
