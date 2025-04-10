<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import SharedDeleteButton from './shared/delete_button.vue';

export default {
  components: {
    GlSprintf,
    GlLink,
    SharedDeleteButton,
  },
  props: {
    confirmPhrase: {
      type: String,
      required: true,
    },
    nameWithNamespace: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
    delayedDeletionDate: {
      type: String,
      required: true,
    },
    restoreHelpPath: {
      type: String,
      required: true,
    },
    isFork: {
      type: Boolean,
      required: true,
    },
    issuesCount: {
      type: Number,
      required: true,
    },
    mergeRequestsCount: {
      type: Number,
      required: true,
    },
    forksCount: {
      type: Number,
      required: true,
    },
    starsCount: {
      type: Number,
      required: true,
    },
    buttonText: {
      type: String,
      required: true,
    },
  },

  strings: {
    restoreLabel: __('Restoring projects'),
    restoreMessage: __('This project can be restored until %{date}.'),
  },
};
</script>

<template>
  <shared-delete-button
    :confirm-phrase="confirmPhrase"
    :name-with-namespace="nameWithNamespace"
    :form-path="formPath"
    :is-fork="isFork"
    :issues-count="issuesCount"
    :merge-requests-count="mergeRequestsCount"
    :forks-count="forksCount"
    :stars-count="starsCount"
    :button-text="buttonText"
  >
    <template #modal-footer>
      <p class="gl-mb-0 gl-mt-3 gl-flex gl-items-center gl-text-subtle">
        <gl-sprintf :message="$options.strings.restoreMessage">
          <template #date>{{ delayedDeletionDate }}</template>
        </gl-sprintf>
        <gl-link
          :aria-label="$options.strings.restoreLabel"
          class="gl-ml-2 gl-flex"
          :href="restoreHelpPath"
          >{{ __('Learn More.') }}
        </gl-link>
      </p>
    </template>
  </shared-delete-button>
</template>
