<script>
import $ from 'jquery';
import Icon from '~/vue_shared/components/icon.vue';
import { inserted } from '~/feature_highlight/feature_highlight_helper';
import {
  mouseenter,
  debouncedMouseleave,
  togglePopover,
} from '~/shared/popover';

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
      .on('mouseleave', debouncedMouseleave(300))
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
