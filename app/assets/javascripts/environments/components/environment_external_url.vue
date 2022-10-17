<script>
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import { s__, __ } from '~/locale';
import { isSafeURL } from '~/lib/utils/url_utility';

/**
 * Renders the external url link in environments table.
 */
export default {
  components: {
    GlButton,
    ModalCopyButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    externalUrl: {
      type: String,
      required: true,
    },
  },
  i18n: {
    title: s__('Environments|Open live environment'),
    open: s__('Environments|Open'),
    copy: __('Copy URL'),
    copyTitle: s__('Environments|Copy live environment URL'),
  },
  computed: {
    isSafeUrl() {
      return isSafeURL(this.externalUrl);
    },
  },
};
</script>
<template>
  <gl-button
    v-if="isSafeUrl"
    v-gl-tooltip
    :title="$options.i18n.title"
    :aria-label="$options.i18n.title"
    :href="externalUrl"
    class="external-url"
    target="_blank"
    icon="external-link"
    rel="noopener noreferrer nofollow"
  >
    {{ $options.i18n.open }}
  </gl-button>
  <modal-copy-button v-else :title="$options.i18n.copyTitle" :text="externalUrl">
    {{ $options.i18n.copy }}
  </modal-copy-button>
</template>
