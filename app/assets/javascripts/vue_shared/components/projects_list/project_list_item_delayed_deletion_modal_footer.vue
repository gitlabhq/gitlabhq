<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'ProjectListItemDelayedDeletionModalFooter',
  components: {
    GlSprintf,
    GlLink,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    projectRestoreMessage: __(
      'This project can be restored until %{date}. %{linkStart}Learn more%{linkEnd}.',
    ),
  },
  computed: {
    showRestoreMessage() {
      return this.project.isAdjournedDeletionEnabled && !this.project.markedForDeletionOn;
    },
  },
  RESTORE_HELP_PATH: helpPagePath('user/project/working_with_projects', {
    anchor: 'restore-a-project',
  }),
};
</script>

<template>
  <p
    v-if="showRestoreMessage"
    class="gl-mb-0 gl-mt-3 gl-text-subtle"
    data-testid="delayed-delete-modal-footer"
  >
    <gl-sprintf :message="$options.i18n.projectRestoreMessage">
      <template #date>{{ project.permanentDeletionDate }}</template>
      <template #link="{ content }">
        <gl-link :href="$options.RESTORE_HELP_PATH">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
  </p>
</template>
