/* global Vue */
(() => {
  Vue.component('time-tracking-no-tracking-pane', {
    name: 'time-tracking-no-tracking-pane',
    template: `
      <div class='time-tracking-no-tracking-pane'>
        <span class='no-value'>No estimate or time spent</span>
      </div>
    `,
  });
})();
