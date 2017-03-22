import Vue from 'vue';

(() => {
  Vue.component('time-tracking-spent-only-pane', {
    name: 'time-tracking-spent-only-pane',
    props: {
      timeSpentHumanReadable: {
        type: String,
        required: true,
      },
    },
    template: `
      <div class='time-tracking-spend-only-pane'>
        <span class='bold'>Spent:</span>
        {{ timeSpentHumanReadable }}
      </div>
    `,
  });
})();
