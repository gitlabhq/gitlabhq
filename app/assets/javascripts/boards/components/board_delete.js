/* eslint-disable no-alert */
export default {
  props: {
    list: {
      type: Object,
      required: true,
    },
  },
  methods: {
    deleteBoard() {
      $(this.$el).tooltip('hide');

      if (confirm('Are you sure you want to delete this list?')) {
        this.list.destroy();
      }
    },
  },
  template: `
    <button
      class="board-delete has-tooltip pull-right"
      type="button"
      title="Delete list"
      aria-label="Delete list"
      data-placement="bottom"
      @click.stop="deleteBoard">
      <i
        class="fa fa-trash"
        ara-hidden="true">
      </i>
    </button>
  `,
};