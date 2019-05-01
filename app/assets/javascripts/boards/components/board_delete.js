import $ from 'jquery';
import Vue from 'vue';
import { __ } from '~/locale';

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
      if (window.confirm(__('Are you sure you want to delete this list?'))) {
        this.list.destroy();
      }
    },
  },
});
