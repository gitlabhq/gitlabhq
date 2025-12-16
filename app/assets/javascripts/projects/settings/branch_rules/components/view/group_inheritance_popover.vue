<script>
import { uniqueId } from 'lodash';
import { GlPopover, GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export const i18n = {
  groupInheritanceTitle: s__('BranchRules|Setting inherited'),
  groupInheritanceDescription: s__(
    'BranchRules|This setting is configured for the group. To make changes, contact a user with required %{linkStart}permissions%{linkEnd}.',
  ),
  groupInheritanceDescriptionCanEdit: s__(
    'BranchRules|This setting is configured for the group. To make changes, go to %{linkStart}group repository settings%{linkEnd}.',
  ),
  // Additional text for screen readers to omit reading out URLs and link tags
  ariaGroupInheritanceDescription: s__(
    'BranchRules|This setting is configured for the group. To make changes, contact a user with required permissions.',
  ),
  ariaGroupInheritanceDescriptionCanEdit: s__(
    'BranchRules|This setting is configured for the group. To make changes, go to group repository settings.',
  ),
};

const groupPermissionsHelpDocLink = helpPagePath('user/permissions#group-repositories');

export default {
  name: 'GroupInheritancePopover',
  i18n,
  groupPermissionsHelpDocLink,
  components: {
    GlPopover,
    GlSprintf,
    GlLink,
    GlIcon,
  },
  inject: ['canAdminGroupProtectedBranches', 'groupSettingsRepositoryPath'],
  computed: {
    triggerId() {
      return uniqueId('group-level-inheritance-info-');
    },
    popoverMessage() {
      return this.canAdminGroupProtectedBranches
        ? this.$options.i18n.groupInheritanceDescriptionCanEdit
        : this.$options.i18n.groupInheritanceDescription;
    },
    ariaLabelMessage() {
      return this.canAdminGroupProtectedBranches
        ? this.$options.i18n.ariaGroupInheritanceDescriptionCanEdit
        : this.$options.i18n.ariaGroupInheritanceDescription;
    },
    linkHref() {
      return this.canAdminGroupProtectedBranches
        ? this.groupSettingsRepositoryPath
        : this.$options.groupPermissionsHelpDocLink;
    },
  },
};
</script>

<template>
  <div>
    <button
      :id="triggerId"
      class="gl-ml-2 gl-border-0 gl-bg-transparent gl-p-2 gl-leading-0"
      :aria-label="`${$options.i18n.groupInheritanceTitle}. ${ariaLabelMessage}`"
    >
      <gl-icon name="lock" variant="disabled" />
    </button>
    <gl-popover
      triggers="hover focus"
      :target="triggerId"
      :title="$options.i18n.groupInheritanceTitle"
    >
      <div>
        <gl-sprintf :message="popoverMessage">
          <template #link="{ content }">
            <gl-link :href="linkHref">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
    </gl-popover>
  </div>
</template>
