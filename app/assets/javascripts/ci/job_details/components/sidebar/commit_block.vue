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
  },
};
</script>
<template>
  <div>
    <span class="gl-font-weight-bold">{{ __('Commit') }}</span>

    <gl-link :href="commit.commit_path" class="gl-text-blue-600!" data-testid="commit-sha">
      {{ commit.short_id }}
    </gl-link>

    <clipboard-button
      :text="commit.id"
      :title="__('Copy commit SHA')"
      category="tertiary"
      size="small"
    />

    <span v-if="mergeRequest">
      {{ __('in') }}
      <gl-link :href="mergeRequest.path" class="gl-text-blue-600!" data-testid="link-commit"
        >!{{ mergeRequest.iid }}</gl-link
      >
    </span>

    <p class="gl-mb-0">{{ commit.title }}</p>
  </div>
</template>
