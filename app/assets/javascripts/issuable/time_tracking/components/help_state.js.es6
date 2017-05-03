/* global Vue */
(() => {
  Vue.component('time-tracking-help-state', {
    name: 'time-tracking-help-state',
    props: ['docsUrl'],
    template: `
      <div class='time-tracking-help-state'>
        <div class='time-tracking-info'>
          <h4>Track time with slash commands</h4>
          <p>Slash commands can be used in the issues description and comment boxes.</p>
          <p>
            <code>/estimate</code>
            will update the estimated time with the latest command.
          </p>
          <p>
            <code>/spend</code>
            will update the sum of the time spent.
          </p>
          <a class='btn btn-default learn-more-button' :href='docsUrl'>Learn more</a>
        </div>
      </div>
    `,
  });
})();
