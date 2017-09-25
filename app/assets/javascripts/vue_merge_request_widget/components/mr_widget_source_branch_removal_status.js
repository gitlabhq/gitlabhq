import tooltip from '../../vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  template: `
    <p class="mr-info-list mr-links">
      <strong>Removes</strong> source branch
      <i
        v-tooltip
        class="fa fa-question-circle"
        title="A user with write access to the source branch selected this option"
        aria-label="Source Branch Removal Info"
      >
      </i>
    </p>
  
  
  `,
};