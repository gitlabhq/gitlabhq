<script>
import { GlSprintf, GlIcon } from '@gitlab/ui';
import { SHORT_DATE_FORMAT } from '~/vue_shared/constants';
import { s__ } from '~/locale';
import { formatDate, newDate } from '~/lib/utils/datetime_utility';
import SafeHtml from '~/vue_shared/directives/safe_html';
import ListItemDescription from '~/vue_shared/components/resource_lists/list_item_description.vue';

export default {
  name: 'ProjectListItemDescription',
  i18n: {
    scheduledDeletion: s__('Projects|Scheduled for deletion on %{date}'),
  },
  components: {
    ListItemDescription,
    GlSprintf,
    GlIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    isPendingDeletion() {
      return Boolean(this.project.markedForDeletionOn);
    },
    formattedDate() {
      return formatDate(newDate(this.project.permanentDeletionDate), SHORT_DATE_FORMAT);
    },
    showDescription() {
      return this.project.descriptionHtml && !this.project.archived;
    },
  },
};
</script>

<template>
  <div v-if="isPendingDeletion" class="md gl-mt-2 gl-text-sm gl-text-secondary">
    <gl-icon name="calendar" />
    <gl-sprintf :message="$options.i18n.scheduledDeletion">
      <template #date>
        {{ formattedDate }}
      </template>
    </gl-sprintf>
  </div>
  <list-item-description v-else-if="showDescription" :description-html="project.descriptionHtml" />
</template>
