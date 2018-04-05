<script>
import $ from 'jquery';
import _ from 'underscore';
import Icon from '~/vue_shared/components/icon.vue';
import {
  togglePopover,
  inserted,
  mouseenter,
  mouseleave,
} from '~/feature_highlight/feature_highlight_helper';

export default {
  name: 'SecurityReportsHelpPopover',
  components: {
    Icon,
  },
  props: {
    options: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    $(this.$el)
      .popover({
        html: true,
        trigger: 'focus',
        container: 'body',
        placement: 'top',
        template:
          '<div class="popover" role="tooltip"><div class="arrow"></div><p class="popover-title"></p><div class="popover-content"></div></div>',
        ...this.options,
      })
      .on('mouseenter', mouseenter)
      .on('mouseleave', _.debounce(mouseleave, 300))
      .on('inserted.bs.popover', inserted)
      .on('show.bs.popover', () => {
        window.addEventListener('scroll', togglePopover.bind(this.$el, false), { once: true });
      });
  },
};
</script>
<template>
  <button
    type="button"
    class="btn btn-blank btn-transparent btn-help"
    tabindex="0"
  >
    <icon name="question" />
  </button>
</template>
