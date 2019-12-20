<script>
import $ from 'jquery';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import Clipboard from 'clipboard';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    Icon,
  },

  directives: {
    GlTooltip: GlTooltipDirective,
  },

  props: {
    text: {
      type: String,
      required: false,
      default: '',
    },
    container: {
      type: String,
      required: false,
      default: '',
    },
    cssClasses: {
      type: String,
      required: false,
      default: '',
    },
    modalId: {
      type: String,
      required: false,
      default: '',
    },
    target: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: true,
    },
    tooltipPlacement: {
      type: String,
      required: false,
      default: 'top',
    },
    tooltipContainer: {
      type: String,
      required: false,
      default: null,
    },
  },

  copySuccessText: __('Copied'),

  computed: {
    modalDomId() {
      return this.modalId ? `#${this.modalId}` : '';
    },
  },

  mounted() {
    this.$nextTick(() => {
      this.clipboard = new Clipboard(this.$el, {
        container:
          document.querySelector(`${this.modalDomId} div.modal-content`) ||
          document.getElementById(this.container) ||
          document.body,
      });
      this.clipboard
        .on('success', e => {
          this.updateTooltip(e.trigger);
          this.$emit('success', e);
          // Clear the selection and blur the trigger so it loses its border
          e.clearSelection();
          $(e.trigger).blur();
        })
        .on('error', e => this.$emit('error', e));
    });
  },

  destroyed() {
    if (this.clipboard) {
      this.clipboard.destroy();
    }
  },

  methods: {
    updateTooltip(target) {
      const $target = $(target);
      const originalTitle = $target.data('originalTitle');

      if ($target.tooltip) {
        /**
         *  The original tooltip will continue staying there unless we remove it by hand.
         *  $target.tooltip('hide') isn't working.
         */
        $('.tooltip').remove();
        $target.attr('title', this.$options.copySuccessText);
        $target.tooltip('_fixTitle');
        $target.tooltip('show');
        $target.attr('title', originalTitle);
        $target.tooltip('_fixTitle');
      }
    },
  },
};
</script>
<template>
  <gl-button
    v-gl-tooltip="{ placement: tooltipPlacement, container: tooltipContainer }"
    :class="cssClasses"
    :data-clipboard-target="target"
    :data-clipboard-text="text"
    :title="title"
  >
    <slot>
      <icon name="duplicate" />
    </slot>
  </gl-button>
</template>
