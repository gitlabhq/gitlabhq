<script>
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  components: {
    ClipboardButton,
  },
  props: {
    pipelineShortSha: {
      type: String,
      required: true,
    },
    pipelineShaPath: {
      type: String,
      required: true,
    },
    mergeRequestReference: {
      type: String,
      required: false,
      default: null,
    },
    mergeRequestPath: {
      type: String,
      required: false,
      default: null,
    },
    gitCommitTitlte: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="block">
    <p>
      {{ __('Commit') }}

      <a
        :href="pipelineShaPath"
        class="js-commit-sha commit-sha link-commit"
      >
        {{ pipelineShortSha }}
      </a>

      <clipboard-button
        :text="pipelineShortSha"
        :title="__('Copy commit SHA to clipboard')"
      />

      <a
        v-if="mergeRequestPath && mergeRequestReference"
        :href="mergeRequestPath"
        class="js-link-commit link-commit"
      >
        {{ mergeRequestReference }}
      </a>
    </p>

    <p class="build-light-text append-bottom-0">
      {{ gitCommitTitlte }}
    </p>
  </div>
</template>
