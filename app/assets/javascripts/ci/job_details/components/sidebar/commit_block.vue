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
    <p class="gl-mb-0 gl-flex gl-flex-wrap gl-items-baseline gl-gap-2">
      <span class="gl-flex gl-font-bold">{{ __('Commit') }}</span>

      <gl-link :href="commit.commit_path" class="commit-sha-container" data-testid="commit-sha">
        {{ commit.short_id }}
      </gl-link>

      <clipboard-button
        :text="commit.id"
        :title="__('Copy commit SHA')"
        category="tertiary"
        size="small"
        class="gl-self-center"
      />

      <span v-if="mergeRequest">
        {{ __('in') }}
        <gl-link :href="mergeRequest.path" class="!gl-text-link" data-testid="link-commit"
          >!{{ mergeRequest.iid }}</gl-link
        >
      </span>
    </p>

    <p class="gl-mb-0 gl-break-all gl-text-subtle">{{ commit.title }}</p>
  </div>
</template>
