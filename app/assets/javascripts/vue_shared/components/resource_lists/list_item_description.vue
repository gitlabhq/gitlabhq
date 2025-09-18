<script>
import { GlTruncateText, GlSprintf, GlIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { SHORT_DATE_FORMAT } from '~/vue_shared/constants';
import { formatDate, newDate } from '~/lib/utils/datetime_utility';

export default {
  i18n: {
    showMore: __('Show more'),
    showLess: __('Show less'),
    scheduledDeletion: s__('ResourceListItem|Scheduled for deletion on %{date}'),
  },
  truncateTextToggleButtonProps: { class: '!gl-text-sm' },
  components: {
    GlTruncateText,
    GlSprintf,
    GlIcon,
  },
  directives: {
    SafeHtml,
  },
  inheritAttrs: false,
  props: {
    resource: {
      type: Object,
      required: true,
    },
  },
  computed: {
    descriptionHtml() {
      return this.resource.descriptionHtml;
    },
    isPendingDeletion() {
      return Boolean(this.resource.markedForDeletion);
    },
    formattedDate() {
      return formatDate(newDate(this.resource.permanentDeletionDate), SHORT_DATE_FORMAT);
    },
    showDescription() {
      return this.resource.descriptionHtml && !this.resource.archived;
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
  <gl-truncate-text
    v-else-if="showDescription"
    :lines="2"
    :mobile-lines="2"
    :show-more-text="$options.i18n.showMore"
    :show-less-text="$options.i18n.showLess"
    :toggle-button-props="$options.truncateTextToggleButtonProps"
    class="gl-mt-2 gl-max-w-88"
  >
    <div
      v-safe-html="descriptionHtml"
      v-bind="$attrs"
      class="md md-child-content-text-subtle gl-text-sm"
      data-testid="description"
    ></div>
  </gl-truncate-text>
</template>
