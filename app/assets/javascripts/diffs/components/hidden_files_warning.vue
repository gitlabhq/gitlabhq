<script>
import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';

export const i18n = {
  plainDiff: __('Plain diff'),
  emailPatch: __('Patches'),
  download: __('To view all changes, download the diff.'),
};

export default {
  name: 'HiddenFilesWarning',
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
    listedCount() {
      // Accepts a number or a "N+" string; pluralization and display use the integer.
      return parseInt(this.total, 10) || 0;
    },
    hasUnlistedFiles() {
      return String(this.total).includes('+');
    },
    collapsedCount() {
      return this.listedCount - this.visible;
    },
    title() {
      if (this.hasUnlistedFiles) {
        return sprintf(
          n__(
            'Only the first %{count} file is listed on this page',
            'Only the first %{count} files are listed on this page',
            this.listedCount,
          ),
          { count: this.listedCount },
        );
      }

      return sprintf(
        n__('%{count} file is collapsed', '%{count} files are collapsed', this.collapsedCount),
        { count: this.collapsedCount },
      );
    },
    collapsedNote() {
      return n__(
        '%{count} of these files is collapsed.',
        '%{count} of these files are collapsed.',
        this.collapsedCount,
      );
    },
  },
};
</script>

<template>
  <gl-alert variant="warning" class="gl-mb-5" :title="title" :dismissible="false">
    <gl-sprintf v-if="hasUnlistedFiles && collapsedCount > 0" :message="collapsedNote">
      <template #count>
        <strong>{{ collapsedCount }}</strong>
      </template>
    </gl-sprintf>
    {{ $options.i18n.download }}
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
