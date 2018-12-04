import $ from 'jquery';
import Vue from 'vue';

export default Vue.extend({
  props: {
    list: {
      type: Object,
      default: () => ({}),
    },
  },
  methods: {
    deleteBoard() {
      $(this.$el).tooltip('hide');

      // eslint-disable-next-line no-alert
      if (window.confirm('Are you sure you want to delete this list?')) {
        this.list.destroy();
      }
    },
  },
});
