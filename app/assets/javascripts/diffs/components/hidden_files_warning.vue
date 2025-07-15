<script>
import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export const i18n = {
  title: __('Some changes are not shown.'),
  plainDiff: __('Plain diff'),
  emailPatch: __('Patches'),
};

export default {
  i18n,
  components: {
    GlAlert,
    GlButton,
    GlSprintf,
  },
  props: {
    total: {
      type: [Number, String],
      required: true,
    },
    visible: {
      type: Number,
      required: true,
    },
    plainDiffPath: {
      type: String,
      default: undefined,
      required: false,
    },
    emailPatchPath: {
      type: String,
      default: undefined,
      required: false,
    },
  },
  computed: {
    message() {
      return sprintf(
        __(`For a faster browsing experience, only %{strongStart}%{visible} of %{total}%{strongEnd} files are shown.
          Download one of the files below to see all changes.`),
        { visible: this.visible, total: this.total },
      );
    },
  },
};
</script>

<template>
  <gl-alert variant="warning" class="gl-mb-5" :title="$options.i18n.title" :dismissible="false">
    <gl-sprintf :message="message">
      <template #strong="{ content }">
        <strong>{{ content }}</strong>
      </template>
    </gl-sprintf>
    <template #actions>
      <gl-button v-if="plainDiffPath" :href="plainDiffPath" class="gl-alert-action gl-mr-3">
        {{ $options.i18n.plainDiff }}
      </gl-button>
      <gl-button v-if="emailPatchPath" :href="emailPatchPath" class="gl-alert-action">
        {{ $options.i18n.emailPatch }}
      </gl-button>
    </template>
  </gl-alert>
</template>
