<script>
import $ from 'jquery';
import { GlIcon } from '@gitlab/ui';
import { inserted } from '~/feature_highlight/feature_highlight_helper';
import { mouseenter, debouncedMouseleave, togglePopover } from '~/shared/popover';

/**
 * Render a button with a question mark icon
 * On hover shows a popover. The popover will be dismissed on mouseleave
 */
export default {
  name: 'HelpPopover',
  components: {
    GlIcon,
  },
  props: {
    options: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  mounted() {
    const $el = $(this.$el);

    $el
      .popover({
        html: true,
        trigger: 'focus',
        container: 'body',
        placement: 'top',
        template:
          '<div class="popover" role="tooltip"><div class="arrow"></div><p class="popover-header"></p><div class="popover-body"></div></div>',
        ...this.options,
      })
      .on('mouseenter', mouseenter)
      .on('mouseleave', debouncedMouseleave(300))
      .on('inserted.bs.popover', inserted)
      .on('show.bs.popover', () => {
        window.addEventListener('scroll', togglePopover.bind($el, false), { once: true });
      });
  },
};
</script>
<template>
  <button type="button" class="btn btn-blank btn-transparent btn-help" tabindex="0">
    <gl-icon name="question" />
  </button>
</template>
