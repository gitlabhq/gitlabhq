<script>
import { GlBadge, GlPopover } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';

export default {
  name: 'GroupBadge',
  i18n: {
    groupLabel: s__('BranchRules|group'),
    inheritedBranchRuleTitle: s__('BranchRules|Inherited branch rule'),
    inheritedBranchRuleContent: s__(
      'BranchRules|This branch rule is inherited from the group Protected branches settings.',
    ),
  },
  components: {
    GlBadge,
    GlPopover,
  },
  computed: {
    groupBadgeId() {
      return uniqueId('group-badge-');
    },
  },
};
</script>

<template>
  <button
    :id="groupBadgeId"
    :aria-label="`${$options.i18n.inheritedBranchRuleTitle}. ${$options.i18n.inheritedBranchRuleContent}`"
    class="gl-inline-block gl-rounded-full gl-border-0 gl-bg-transparent gl-p-0 gl-leading-0"
  >
    <gl-badge variant="tier">
      {{ $options.i18n.groupLabel }}
    </gl-badge>

    <gl-popover :target="groupBadgeId" :title="$options.i18n.inheritedBranchRuleTitle">
      {{ $options.i18n.inheritedBranchRuleContent }}
    </gl-popover>
  </button>
</template>
