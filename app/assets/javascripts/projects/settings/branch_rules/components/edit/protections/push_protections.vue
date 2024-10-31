<script>
import { GlFormGroup, GlSprintf, GlLink, GlFormCheckbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export const i18n = {
  allowedToPush: s__('BranchRules|Allowed to push and merge'),
  forcePushTitle: s__(
    'BranchRules|Allow all users with push access to %{linkStart}force push%{linkEnd}.',
  ),
};

export default {
  name: 'BranchPushProtections',
  i18n,
  components: {
    GlFormGroup,
    GlSprintf,
    GlLink,
    GlFormCheckbox,
  },
  forcePushHelpPath: helpPagePath('topics/git/git_rebase', {
    anchor: 'force-push-to-a-remote-branch',
  }),
  props: {
    membersAllowedToPush: {
      type: Array,
      required: true,
    },
    allowForcePush: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.allowedToPush">
    <!-- TODO: add multi-select-dropdown (https://gitlab.com/gitlab-org/gitlab/-/issues/362212) -->

    <gl-form-checkbox
      class="gl-mt-5"
      :checked="allowForcePush"
      @change="$emit('change-allow-force-push', $event)"
    >
      <gl-sprintf :message="$options.i18n.forcePushTitle">
        <template #link="{ content }">
          <gl-link :href="$options.forcePushHelpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-form-checkbox>
  </gl-form-group>
</template>
