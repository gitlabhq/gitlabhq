<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  lockedIssueDocsPath: helpPagePath('user/discussions/_index.md', {
    anchor: 'prevent-comments-by-locking-the-discussion',
  }),
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
};
</script>

<template>
  <div class="issuable-note-warning gl-relative gl-rounded-base gl-py-4">
    <gl-icon name="lock" class="gl-mr-2" />
    <gl-sprintf
      :message="
        __('Discussion is %{lockedLinkStart}locked%{lockedLinkEnd}. Only members can comment.')
      "
    >
      <template #lockedLink="{ content }">
        <gl-link :href="$options.lockedIssueDocsPath">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </div>
</template>
