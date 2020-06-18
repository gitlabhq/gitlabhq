import $ from 'jquery';
import Vue from 'vue';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default Vue.extend({
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    list: {
      type: Object,
      default: () => ({}),
      required: false,
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
