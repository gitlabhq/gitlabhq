<script>
import { s__ } from '~/locale';
import HoverBadge from './hover_badge.vue';

export default {
  name: 'ExperimentBadge',
  components: { HoverBadge },
  i18n: {
    badgeLabel: s__('ExperimentBadge|Experiment'),
    popoverTitle: s__("ExperimentBadge|What's an experiment?"),
    descriptionParagraph: s__(
      'ExperimentBadge|An experiment is not yet production-ready, but is released for initial testing and feedback during development.',
    ),
    listIntroduction: s__('ExperimentBadge|Experiments:'),
    listItemStability: s__('ExperimentBadge|Might be unstable or cause data loss.'),
    listItemNoSupport: s__('ExperimentBadge|Are not supported and might not be documented.'),
    listItemCanBeRemoved: s__('ExperimentBadge|Could be changed or removed at any time.'),
    listItemTestAgreement: s__('ExperimentBadge|Are subject to the GitLab Testing Agreement.'),
  },
};
</script>

<template>
  <hover-badge :label="$options.i18n.badgeLabel" :title="$options.i18n.popoverTitle">
    <p>{{ $options.i18n.descriptionParagraph }}</p>

    <p class="gl-mb-0">{{ $options.i18n.listIntroduction }}</p>

    <ul class="gl-pl-4">
      <li>{{ $options.i18n.listItemStability }}</li>
      <li>{{ $options.i18n.listItemNoSupport }}</li>
      <li>{{ $options.i18n.listItemCanBeRemoved }}</li>
      <li>{{ $options.i18n.listItemTestAgreement }}</li>
    </ul>
  </hover-badge>
</template>
