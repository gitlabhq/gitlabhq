<script>
import { GlLink, GlIcon, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  docsLinks: {
    locked: helpPagePath('user/discussions/_index', {
      anchor: 'prevent-comments-by-locking-the-discussion',
    }),
    confidential: helpPagePath('user/discussions/_index', {
      anchor: 'comments-on-confidential-items',
    }),
  },
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    isLocked: {
      type: Boolean,
      default: false,
      required: false,
    },
    isConfidential: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    warningIcon() {
      if (this.isConfidential) return 'eye-slash';
      if (this.isLocked) return 'lock';

      return '';
    },
    isLockedAndConfidential() {
      return this.isConfidential && this.isLocked;
    },
  },
};
</script>
<template>
  <div class="issuable-note-warning" data-testid="issuable-note-warning">
    <gl-icon
      v-if="!isLockedAndConfidential"
      :name="warningIcon"
      :size="16"
      class="icon gl-inline-block"
    />

    <span v-if="isLockedAndConfidential" ref="lockedAndConfidential">
      <span>
        <gl-sprintf
          :message="
            __(
              'Marked as %{confidentialLinkStart}confidential%{confidentialLinkEnd} and discussion is %{lockedLinkStart}locked%{lockedLinkEnd}. People without permission will never get a notification and won\'t be able to comment.',
            )
          "
        >
          <template #confidentialLink="{ content }">
            <gl-link :href="$options.docsLinks.confidential" target="_blank">{{ content }}</gl-link>
          </template>
          <template #lockedLink="{ content }">
            <gl-link :href="$options.docsLinks.locked" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </span>
    </span>

    <span v-else-if="isConfidential" ref="confidential">
      <gl-sprintf
        :message="
          __(
            'Marked as %{confidentialLinkStart}confidential%{confidentialLinkEnd}. People without permission will never get a notification.',
          )
        "
      >
        <template #confidentialLink="{ content }">
          <gl-link :href="$options.docsLinks.confidential" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </span>

    <span v-else-if="isLocked" ref="locked">
      <gl-sprintf
        :message="
          __('Discussion is %{lockedLinkStart}locked%{lockedLinkEnd}. Only members can comment.')
        "
      >
        <template #lockedLink="{ content }">
          <gl-link :href="$options.docsLinks.locked" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </span>
  </div>
</template>
