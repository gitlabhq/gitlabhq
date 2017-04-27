export default {
  props: {
    count: {
      type: Number,
      required: true,
    },
  },
  template: `
    <span v-if="count === 50 || true" class="events-info pull-right">
      <i class="fa fa-warning has-tooltip"
          aria-hidden="true"
          :title="__('Limited to showing 50 events at most')"
          data-placement="top"></i>
      {{ n__('Showing %d event', 'Showing %d events', 50) }}
    </span>
  `,
};
