((gl) => {
  Vue.component('time-tracking-estimate-only-pane', {
    name: 'time-tracking-estimate-only-pane',
    props: ['timeEstimateHuman'],
    template: `
      <div class='time-tracking-estimate-only-pane'>
        <span class='bold'>Estimated:</span>
        {{ timeEstimateHuman }}
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
