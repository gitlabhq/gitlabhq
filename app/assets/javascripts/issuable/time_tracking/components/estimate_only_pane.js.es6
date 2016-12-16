/* global Vue */
(() => {
  Vue.component('time-tracking-estimate-only-pane', {
    name: 'time-tracking-estimate-only-pane',
    props: ['timeEstimateHumanReadable'],
    template: `
      <div class='time-tracking-estimate-only-pane'>
        <span class='bold'>Estimated:</span>
        {{ timeEstimateHumanReadable }}
      </div>
    `,
  });
})();
