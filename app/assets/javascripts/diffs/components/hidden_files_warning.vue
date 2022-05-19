<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';

export const i18n = {
  title: __('Too many changes to show.'),
  plainDiff: __('Plain diff'),
  emailPatch: __('Email patch'),
};

export default {
  i18n,
  components: {
    GlAlert,
    GlSprintf,
  },
  props: {
    total: {
      type: String,
      required: true,
    },
    visible: {
      type: Number,
      required: true,
    },
    plainDiffPath: {
      type: String,
      required: true,
    },
    emailPatchPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-alert
    variant="warning"
    :title="$options.i18n.title"
    :primary-button-text="$options.i18n.plainDiff"
    :primary-button-link="plainDiffPath"
    :secondary-button-text="$options.i18n.emailPatch"
    :secondary-button-link="emailPatchPath"
    :dismissible="false"
  >
    <gl-sprintf
      :message="
        sprintf(
          __(
            'To preserve performance only %{strongStart}%{visible} of %{total}%{strongEnd} files are displayed.',
          ),
          { visible, total } /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */,
        )
      "
    >
      <template #strong="{ content }">
        <strong>{{ content }}</strong>
      </template>
    </gl-sprintf>
  </gl-alert>
</template>
