<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import Clipboard from 'clipboard';
import { uniqueId } from 'lodash';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';

export default {
  components: {
    GlButton,
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
    id: {
      type: String,
      required: false,
      default: () => uniqueId('modal-copy-button-'),
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
    category: {
      type: String,
      required: false,
      default: 'primary',
    },
  },
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
        .on('success', (e) => {
          this.$root.$emit(BV_HIDE_TOOLTIP, this.id);
          this.$emit('success', e);
          // Clear the selection and blur the trigger so it loses its border
          e.clearSelection();
          e.trigger.blur();
        })
        .on('error', (e) => this.$emit('error', e));
    });
  },
  destroyed() {
    if (this.clipboard) {
      this.clipboard.destroy();
    }
  },
};
</script>
<template>
  <gl-button
    :id="id"
    v-gl-tooltip="{ placement: tooltipPlacement, container: tooltipContainer }"
    :class="cssClasses"
    :data-clipboard-target="target"
    :data-clipboard-text="text"
    :title="title"
    :aria-label="title"
    :category="category"
    icon="copy-to-clipboard"
  />
</template>
