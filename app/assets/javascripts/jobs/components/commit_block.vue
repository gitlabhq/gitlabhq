<script>
import { GlLink } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  components: {
    ClipboardButton,
    GlLink,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
    mergeRequest: {
      type: Object,
      required: false,
      default: null,
    },
    isLastBlock: {
      type: Boolean,
      required: true,
    },
  },
};
</script>
<template>
  <div
    :class="{
      'block-last': isLastBlock,
      block: !isLastBlock,
    }"
  >
    <p>
      {{ __('Commit') }}

      <gl-link :href="commit.commit_path" class="js-commit-sha commit-sha link-commit">{{
        commit.short_id
      }}</gl-link>

      <clipboard-button
        :text="commit.short_id"
        :title="__('Copy commit SHA to clipboard')"
        css-class="btn btn-clipboard btn-transparent"
      />

      <gl-link v-if="mergeRequest" :href="mergeRequest.path" class="js-link-commit link-commit"
        >!{{ mergeRequest.iid }}</gl-link
      >
    </p>

    <p class="build-light-text append-bottom-0">{{ commit.title }}</p>
  </div>
</template>
