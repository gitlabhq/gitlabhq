<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DOCS_URL } from 'jh_else_ce/lib/utils/url_utility';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
  },
  I18N_INSTRUCTIONS_TEXT: s__(
    'Runners|To install Runner in Kubernetes follow the instructions described in the GitLab documentation.',
  ),
  I18N_VIEW_INSTRUCTIONS: s__('Runners|View installation instructions'),
  HELP_URL: `${DOCS_URL}/runner/install/kubernetes.html`,
};
</script>
<template>
  <div>
    <p>
      {{ $options.I18N_INSTRUCTIONS_TEXT }}
    </p>
    <gl-button :href="$options.HELP_URL">
      <gl-icon name="external-link" />
      {{ $options.I18N_VIEW_INSTRUCTIONS }}
    </gl-button>
    <footer class="gl-flex gl-justify-end gl-pt-3">
      <gl-button @click="onClose()">{{ __('Close') }}</gl-button>
    </footer>
  </div>
</template>
