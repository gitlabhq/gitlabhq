<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'GroupListItemDelayedDeletionModalFooter',
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    groupRestoreMessage: __(
      'This group can be restored until %{date}. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  computed: {
    isMarkedForDeletion() {
      return Boolean(this.group.markedForDeletionOn);
    },
    canBeMarkedForDeletion() {
      return this.group.isAdjournedDeletionEnabled && !this.isMarkedForDeletion;
    },
  },
  HELP_PAGE_PATH: helpPagePath('user/group/_index', { anchor: 'restore-a-group' }),
};
</script>

<template>
  <p
    v-if="canBeMarkedForDeletion"
    class="gl-mb-0 gl-mt-3 gl-text-subtle"
    data-testid="delayed-delete-modal-footer"
  >
    <gl-sprintf :message="$options.i18n.groupRestoreMessage">
      <template #date>{{ group.permanentDeletionDate }}</template>
      <template #link="{ content }">
        <gl-link :href="$options.HELP_PAGE_PATH">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </p>
</template>
