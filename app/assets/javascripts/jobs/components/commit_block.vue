<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
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
    <p class="append-bottom-5">
      <span class="font-weight-bold">{{ __('Commit') }}</span>

      <gl-link :href="commit.commit_path" class="js-commit-sha commit-sha link-commit">
        {{ commit.short_id }}
      </gl-link>

      <clipboard-button
        :text="commit.id"
        :title="__('Copy commit SHA to clipboard')"
        css-class="btn btn-clipboard btn-transparent"
      />

      <span v-if="mergeRequest">
        in
        <gl-link :href="mergeRequest.path" class="js-link-commit link-commit"
          >!{{ mergeRequest.iid }}</gl-link
        >
      </span>
    </p>

    <p class="append-bottom-0">{{ commit.title }}</p>
  </div>
</template>
