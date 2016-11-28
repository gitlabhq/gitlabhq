(() => {
  gl.IssuableTimeTrackingApp.spentOnlyPane = {
    name: 'time-tracking-spent-only-pane',
    props: ['timeSpentHuman'],
    template: `
      <div class='time-tracking-spend-only-pane'>
        <span class='bold'>Spent:</span>
        {{ timeSpentHuman }}
      </div>
    `,
  };
})(gl.IssuableTimeTrackingApp || (gl.IssuableTimeTrackingApp = {}));
