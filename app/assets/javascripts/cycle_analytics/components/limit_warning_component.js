export default {
  props: {
    count: {
      type: Number,
      required: true,
    },
  },
  template: `
    <span v-if="count === 50" class="events-info pull-right">
      <i class="fa fa-warning has-tooltip"
          aria-hidden="true"
          title="Limited to showing 50 events at most"
          data-placement="top"></i>
      Showing 50 events
    </span>
  `,
};
