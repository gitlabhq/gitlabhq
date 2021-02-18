<script>
import { GlSprintf, GlButton } from '@gitlab/ui';
import { sprintf, n__ } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import {
  DETAILS_PAGE_TITLE,
  UPDATED_AT,
  CLEANUP_UNSCHEDULED_TEXT,
  CLEANUP_SCHEDULED_TEXT,
  CLEANUP_ONGOING_TEXT,
  CLEANUP_UNFINISHED_TEXT,
  CLEANUP_DISABLED_TEXT,
  CLEANUP_SCHEDULED_TOOLTIP,
  CLEANUP_ONGOING_TOOLTIP,
  CLEANUP_UNFINISHED_TOOLTIP,
  CLEANUP_DISABLED_TOOLTIP,
  UNFINISHED_STATUS,
  UNSCHEDULED_STATUS,
  SCHEDULED_STATUS,
  ONGOING_STATUS,
} from '../../constants/index';

export default {
  name: 'DetailsHeader',
  components: { GlSprintf, GlButton, TitleArea, MetadataItem },
  mixins: [timeagoMixin],
  props: {
    image: {
      type: Object,
      required: true,
    },
    metadataLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    visibilityIcon() {
      return this.image?.project?.visibility === 'public' ? 'eye' : 'eye-slash';
    },
    timeAgo() {
      return this.timeFormatted(this.image.updatedAt);
    },
    updatedText() {
      return sprintf(UPDATED_AT, { time: this.timeAgo });
    },
    tagCountText() {
      return n__('%d tag', '%d tags', this.image.tagsCount);
    },
    cleanupTextAndTooltip() {
      if (!this.image.project.containerExpirationPolicy?.enabled) {
        return { text: CLEANUP_DISABLED_TEXT, tooltip: CLEANUP_DISABLED_TOOLTIP };
      }
      return {
        [UNSCHEDULED_STATUS]: {
          text: sprintf(CLEANUP_UNSCHEDULED_TEXT, {
            time: this.timeFormatted(this.image.project.containerExpirationPolicy.nextRunAt),
          }),
        },
        [SCHEDULED_STATUS]: { text: CLEANUP_SCHEDULED_TEXT, tooltip: CLEANUP_SCHEDULED_TOOLTIP },
        [ONGOING_STATUS]: { text: CLEANUP_ONGOING_TEXT, tooltip: CLEANUP_ONGOING_TOOLTIP },
        [UNFINISHED_STATUS]: { text: CLEANUP_UNFINISHED_TEXT, tooltip: CLEANUP_UNFINISHED_TOOLTIP },
      }[this.image?.expirationPolicyCleanupStatus];
    },
    deleteButtonDisabled() {
      return this.disabled || !this.image.canDelete;
    },
  },
  i18n: {
    DETAILS_PAGE_TITLE,
  },
};
</script>

<template>
  <title-area :metadata-loading="metadataLoading">
    <template #title>
      <span data-testid="title">
        <gl-sprintf :message="$options.i18n.DETAILS_PAGE_TITLE">
          <template #imageName>
            {{ image.name }}
          </template>
        </gl-sprintf>
      </span>
    </template>
    <template #metadata-tags-count>
      <metadata-item icon="tag" :text="tagCountText" data-testid="tags-count" />
    </template>

    <template #metadata-cleanup>
      <metadata-item
        icon="expire"
        :text="cleanupTextAndTooltip.text"
        :text-tooltip="cleanupTextAndTooltip.tooltip"
        size="xl"
        data-testid="cleanup"
      />
    </template>

    <template #metadata-updated>
      <metadata-item
        :icon="visibilityIcon"
        :text="updatedText"
        size="xl"
        data-testid="updated-and-visibility"
      />
    </template>
    <template #right-actions>
      <gl-button
        v-if="!metadataLoading"
        variant="danger"
        :disabled="deleteButtonDisabled"
        @click="$emit('delete')"
      >
        {{ __('Delete') }}
      </gl-button>
    </template>
  </title-area>
</template>
