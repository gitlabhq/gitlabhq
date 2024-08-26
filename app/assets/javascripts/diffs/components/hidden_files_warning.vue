<script>
import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';

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
  <gl-alert variant="warning" class="gl-mb-5" :title="$options.i18n.title" :dismissible="false">
    <gl-sprintf
      :message="
        sprintf(
          __(
            'For a faster browsing experience, only %{strongStart}%{visible} of %{total}%{strongEnd} files are shown. Download one of the files below to see all changes.',
          ),
          { visible, total } /* eslint-disable-line @gitlab/vue-no-new-non-primitive-in-template */,
        )
      "
    >
      <template #strong="{ content }">
        <strong>{{ content }}</strong>
      </template>
    </gl-sprintf>
    <template #actions>
      <gl-button :href="plainDiffPath" class="gl-alert-action gl-mr-3">
        {{ $options.i18n.plainDiff }}
      </gl-button>
      <gl-button :href="emailPatchPath" class="gl-alert-action">
        {{ $options.i18n.emailPatch }}
      </gl-button>
    </template>
  </gl-alert>
</template>
