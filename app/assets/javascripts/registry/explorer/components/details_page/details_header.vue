<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, n__, s__ } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import {
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
  ROOT_IMAGE_TEXT,
  ROOT_IMAGE_TOOLTIP,
} from '../../constants/index';

import getContainerRepositoryTagsCountQuery from '../../graphql/queries/get_container_repository_tags_count.query.graphql';

export default {
  name: 'DetailsHeader',
  components: { GlButton, GlIcon, TitleArea, MetadataItem },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    image: {
      type: Object,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      containerRepository: {},
      fetchTagsCount: false,
    };
  },
  apollo: {
    containerRepository: {
      query: getContainerRepositoryTagsCountQuery,
      variables() {
        return {
          id: this.image.id,
        };
      },
    },
  },
  computed: {
    imageDetails() {
      return { ...this.image, ...this.containerRepository };
    },
    visibilityIcon() {
      return this.imageDetails?.project?.visibility === 'public' ? 'eye' : 'eye-slash';
    },
    timeAgo() {
      return this.timeFormatted(this.imageDetails.updatedAt);
    },
    updatedText() {
      return sprintf(UPDATED_AT, { time: this.timeAgo });
    },
    tagCountText() {
      if (this.$apollo.queries.containerRepository.loading) {
        return s__('ContainerRegistry|-- tags');
      }
      return n__('%d tag', '%d tags', this.imageDetails.tagsCount);
    },
    cleanupTextAndTooltip() {
      if (!this.imageDetails.project.containerExpirationPolicy?.enabled) {
        return { text: CLEANUP_DISABLED_TEXT, tooltip: CLEANUP_DISABLED_TOOLTIP };
      }
      return {
        [UNSCHEDULED_STATUS]: {
          text: sprintf(CLEANUP_UNSCHEDULED_TEXT, {
            time: this.timeFormatted(this.imageDetails.project.containerExpirationPolicy.nextRunAt),
          }),
        },
        [SCHEDULED_STATUS]: { text: CLEANUP_SCHEDULED_TEXT, tooltip: CLEANUP_SCHEDULED_TOOLTIP },
        [ONGOING_STATUS]: { text: CLEANUP_ONGOING_TEXT, tooltip: CLEANUP_ONGOING_TOOLTIP },
        [UNFINISHED_STATUS]: { text: CLEANUP_UNFINISHED_TEXT, tooltip: CLEANUP_UNFINISHED_TOOLTIP },
      }[this.imageDetails?.expirationPolicyCleanupStatus];
    },
    deleteButtonDisabled() {
      return this.disabled || !this.imageDetails.canDelete;
    },
    rootImageTooltip() {
      return !this.imageDetails.name ? ROOT_IMAGE_TOOLTIP : '';
    },
    imageName() {
      return this.imageDetails.name || ROOT_IMAGE_TEXT;
    },
  },
};
</script>

<template>
  <title-area>
    <template #title>
      <span data-testid="title">
        {{ imageName }}
      </span>
      <gl-icon
        v-if="rootImageTooltip"
        v-gl-tooltip="rootImageTooltip"
        class="gl-text-blue-600"
        name="information-o"
        :aria-label="rootImageTooltip"
      />
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
      <gl-button variant="danger" :disabled="deleteButtonDisabled" @click="$emit('delete')">
        {{ __('Delete image repository') }}
      </gl-button>
    </template>
  </title-area>
</template>
