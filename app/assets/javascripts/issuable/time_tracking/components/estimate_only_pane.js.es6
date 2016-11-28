((app) => {
  app.estimateOnlyPane = {
    name: 'time-tracking-estimate-only-pane',
    props: ['timeEstimateHuman'],
    template: `
      <div class='time-tracking-estimate-only-pane'>
        <span class='bold'>Estimated:</span>
        {{ timeEstimateHuman }}
      </div>
    `,
  };
})(gl.IssuableTimeTrackingApp || (gl.IssuableTimeTrackingApp = {}));
