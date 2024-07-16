<script>
import { s__ } from '~/locale';
import HoverBadge from './hover_badge.vue';

export default {
  name: 'BetaBadge',
  components: { HoverBadge },
  i18n: {
    badgeLabel: s__('BetaBadge|Beta'),
    popoverTitle: s__("BetaBadge|What's a beta?"),
    descriptionParagraph: s__(
      "BetaBadge|A beta feature is not yet production-ready, but is ready for testing and unlikely to change significantly before it's released.",
    ),
    listIntroduction: s__('BetaBadge|Beta features:'),
    listItemStability: s__('BetaBadge|Have a low risk of data loss, but might still be unstable.'),
    listItemReasonableEffort: s__(
      'BetaBadge|Are supported on a commercially-reasonable effort basis.',
    ),
    listItemNearCompletion: s__('BetaBadge|Have a near complete user experience.'),
    listItemTestAgreement: s__('BetaBadge|Are subject to the GitLab Testing Agreement.'),
  },
  methods: {
    target() {
      /**
       * BVPopover retrieves the target during the `beforeDestroy` hook to deregister attached
       * events. Since during `beforeDestroy` refs are `undefined`, it throws a warning in the
       * console because we're trying to access the `$el` property of `undefined`. Optional
       * chaining is not working in templates, which is why the method is used.
       *
       * See more on https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49628#note_464803276
       */
      return this.$refs.badge?.$el;
    },
  },
};
</script>

<template>
  <hover-badge :label="$options.i18n.badgeLabel" :title="$options.i18n.popoverTitle">
    <p>{{ $options.i18n.descriptionParagraph }}</p>

    <p class="gl-mb-0">{{ $options.i18n.listIntroduction }}</p>

    <ul class="gl-pl-4">
      <li>{{ $options.i18n.listItemStability }}</li>
      <li>{{ $options.i18n.listItemReasonableEffort }}</li>
      <li>{{ $options.i18n.listItemNearCompletion }}</li>
      <li>{{ $options.i18n.listItemTestAgreement }}</li>
    </ul>
  </hover-badge>
</template>
