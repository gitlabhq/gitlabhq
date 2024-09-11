<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import PushProtections from './push_protections.vue';
import MergeProtections from './merge_protections.vue';

export const i18n = {
  protections: s__('BranchRules|Protections'),
  protectionsHelpText: s__(
    'BranchRules|Keep stable branches secure and force developers to use merge requests. %{linkStart}What are protected branches?%{linkEnd}',
  ),
};

export default {
  name: 'BranchProtections',
  i18n,
  components: {
    GlSprintf,
    GlLink,
    PushProtections,
    MergeProtections,
  },
  protectedBranchesHelpPath: helpPagePath('user/project/repository/branches/protected'),
  props: {
    protections: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <h4 class="gl-border-t gl-pt-4">{{ $options.i18n.protections }}</h4>

    <div data-testid="protections-help-text">
      <gl-sprintf :message="$options.i18n.protectionsHelpText">
        <template #link="{ content }">
          <gl-link :href="$options.protectedBranchesHelpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </div>

    <push-protections
      class="gl-mt-5"
      :members-allowed-to-push="protections.membersAllowedToPush"
      :allow-force-push="protections.allowForcePush"
      v-on="$listeners"
    />

    <merge-protections
      :members-allowed-to-merge="protections.membersAllowedToMerge"
      :require-code-owners-approval="protections.requireCodeOwnersApproval"
      v-on="$listeners"
    />
  </div>
</template>
