export default {
  name: 'time-tracking-help-state',
  props: {
    rootPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    href() {
      return `${this.rootPath}help/workflow/time_tracking.md`;
    },
  },
  template: `
    <div class="time-tracking-help-state">
      <div class="time-tracking-info">
        <h4>
          Track time with quick actions
        </h4>
        <p>
          Quick actions can be used in the issues description and comment boxes.
        </p>
        <p>
          <code>
            /estimate
          </code>
          will update the estimated time with the latest command.
        </p>
        <p>
          <code>
            /spend
          </code>
          will update the sum of the time spent.
        </p>
        <a
          class="btn btn-default learn-more-button"
          :href="href"
        >
          Learn more
        </a>
      </div>
    </div>
  `,
};
