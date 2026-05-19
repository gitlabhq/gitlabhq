<script>
import { GlBadge, GlPopover, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'ObservabilityFeedback',
  components: {
    GlBadge,
    GlPopover,
    GlLink,
  },
  badgeId: 'observability-feedback-badge',
  methods: {
    closeFeedbackPopover() {
      this.$refs.popover?.$emit('close');
    },
  },
  feedbackIssue:
    'https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues/37',
  i18n: {
    badgeTitle: s__('Observability|Give feedback'),
    badgePopoverTitle: s__('Observability|Observability feedback'),
    badgeContent: s__(
      'Observability|We would love to learn more about your experience with GitLab Observability.',
    ),
    feedbackIssueText: s__('Observability|Give feedback on this experience'),
  },
};
</script>

<template>
  <div class="gl-mr-5 gl-content-center @sm/panel:gl-flex">
    <button
      :id="$options.badgeId"
      class="gl-rounded-pill gl-border-none gl-bg-transparent gl-p-0 gl-leading-0"
    >
      <gl-badge variant="info" icon="comment" class="gl-cursor-pointer">{{
        $options.i18n.badgeTitle
      }}</gl-badge>
    </button>
    <gl-popover
      ref="popover"
      :target="$options.badgeId"
      :title="$options.i18n.badgePopoverTitle"
      triggers="focus click"
      placement="bottom"
      show-close-button
    >
      {{ $options.i18n.badgeContent }}
      <gl-link
        target="_blank"
        rel="noopener noreferrer"
        :href="$options.feedbackIssue"
        @click="closeFeedbackPopover"
        >{{ $options.i18n.feedbackIssueText }}</gl-link
      >.
    </gl-popover>
  </div>
</template>
