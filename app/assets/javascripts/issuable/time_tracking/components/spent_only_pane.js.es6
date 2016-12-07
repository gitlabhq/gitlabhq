(() => {
  Vue.component('time-tracking-spent-only-pane', {
    name: 'time-tracking-spent-only-pane',
    props: ['timeSpentHuman'],
    template: `
      <div class='time-tracking-spend-only-pane'>
        <span class='bold'>Spent:</span>
        {{ timeSpentHuman }}
      </div>
    `,
  });
})();
