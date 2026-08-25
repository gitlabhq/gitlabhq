<script>
import { GlModal, GlToastMixin } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import { __ } from '~/locale';
import { copyQuerySource, wrapQueryInGlqlBlock } from '../../utils/common';

export default {
  name: 'GlqlViewSourceModal',
  components: {
    GlModal,
  },
  mixins: [GlToastMixin],
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    query: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['change'],
  computed: {
    modalId() {
      return uniqueId('glql-view-source-modal-');
    },
    wrappedQuery() {
      return wrapQueryInGlqlBlock(this.query);
    },
  },
  methods: {
    async copySource() {
      try {
        await copyQuerySource(this.query, this.$refs.content);
        this.$toast.show(this.$options.i18n.copySuccess);
      } catch {
        this.$toast.show(this.$options.i18n.copyError);
      }
    },
  },
  i18n: {
    copySuccess: __('Source copied to clipboard'),
    copyError: __('Failed to copy source to clipboard'),
  },
  primaryAction: { text: __('Copy source') },
  cancelAction: { text: __('Close') },
};
</script>
<template>
  <gl-modal
    :visible="visible"
    :title="title"
    :modal-id="modalId"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
    @primary="copySource"
    @change="$emit('change', $event)"
  >
    <div ref="content" class="md">
      <div class="markdown-code-block gl-relative">
        <pre
          class="code highlight code-syntax-highlight-theme"
        ><code>{{ wrappedQuery }}</code></pre>
      </div>
    </div>
  </gl-modal>
</template>
