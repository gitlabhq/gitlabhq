<script>
import { s__ } from '~/locale';
import HoverBadge from './hover_badge.vue';

export default {
  name: 'ExperimentBadge',
  components: { HoverBadge },
  i18n: {
    badgeLabel: s__('ExperimentBadge|Experiment'),
    popoverTitle: s__("ExperimentBadge|What's an Experiment?"),
    descriptionParagraph: s__(
      "ExperimentBadge|An Experiment is a feature that's in the process of being developed. It's not production-ready. We encourage users to try Experimental features and provide feedback.",
    ),
    listIntroduction: s__('ExperimentBadge|An Experiment:'),
    listItemStability: s__('ExperimentBadge|May be unstable.'),
    listItemDataLoss: s__('ExperimentBadge|Can cause data loss.'),
    listItemNoSupport: s__('ExperimentBadge|Has no support and might not be documented.'),
    listItemCanBeRemoved: s__('ExperimentBadge|Can be removed at any time.'),
  },
  props: {
    size: {
      type: String,
      required: false,
      default: 'md',
    },
  },
};
</script>

<template>
  <hover-badge :label="$options.i18n.badgeLabel" :size="size" :title="$options.i18n.popoverTitle">
    <p>{{ $options.i18n.descriptionParagraph }}</p>

    <p class="gl-mb-0">{{ $options.i18n.listIntroduction }}</p>

    <ul class="gl-pl-4">
      <li>{{ $options.i18n.listItemStability }}</li>
      <li>{{ $options.i18n.listItemDataLoss }}</li>
      <li>{{ $options.i18n.listItemNoSupport }}</li>
      <li>{{ $options.i18n.listItemCanBeRemoved }}</li>
    </ul>
  </hover-badge>
</template>
