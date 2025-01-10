<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import ProtectedBadge from '~/vue_shared/components/badges/protected_badge.vue';
import { sprintf, n__, s__ } from '~/locale';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { formatDate } from '~/lib/utils/datetime_utility';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import {
  CREATED_AT,
  LAST_PUBLISHED_AT,
  CLEANUP_UNSCHEDULED_TEXT,
  CLEANUP_SCHEDULED_TEXT,
  CLEANUP_ONGOING_TEXT,
  CLEANUP_UNFINISHED_TEXT,
  CLEANUP_DISABLED_TEXT,
  CLEANUP_SCHEDULED_TOOLTIP,
  CLEANUP_ONGOING_TOOLTIP,
  CLEANUP_UNFINISHED_TOOLTIP,
  CLEANUP_DISABLED_TOOLTIP,
  DELETE_IMAGE_TEXT,
  MORE_ACTIONS_TEXT,
  UNFINISHED_STATUS,
  UNSCHEDULED_STATUS,
  SCHEDULED_STATUS,
  ONGOING_STATUS,
  ROOT_IMAGE_TOOLTIP,
} from '../../constants/index';
import getContainerRepositoryMetadata from '../../graphql/queries/get_container_repository_metadata.query.graphql';
import { getImageName } from '../../utils';

export default {
  name: 'DetailsHeader',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlIcon,
    TitleArea,
    MetadataItem,
    ProtectedBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  inject: ['config'],
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
    };
  },
  apollo: {
    containerRepository: {
      query: getContainerRepositoryMetadata,
      variables() {
        return {
          id: this.image.id,
          metadataDatabaseEnabled: this.config.isMetadataDatabaseEnabled,
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
    formattedCreatedAtDate() {
      return this.formatDate(this.imageDetails.createdAt);
    },
    containsLastPublishedAtDate() {
      return Boolean(this.imageDetails.lastPublishedAt);
    },
    formattedLastPublishedAtDate() {
      return this.containsLastPublishedAtDate
        ? this.formatDate(this.imageDetails.lastPublishedAt)
        : '';
    },
    createdText() {
      return sprintf(CREATED_AT, { time: this.formattedCreatedAtDate });
    },
    lastPublishedAtText() {
      return sprintf(LAST_PUBLISHED_AT, { time: this.formattedLastPublishedAtDate });
    },
    tagCountText() {
      if (this.$apollo.queries.containerRepository.loading) {
        return s__('ContainerRegistry|-- tags');
      }
      return n__('%d tag', '%d tags', this.imageDetails.tagsCount);
    },
    cleanupTextAndTooltip() {
      if (!this.imageDetails.project.containerTagsExpirationPolicy?.enabled) {
        return { text: CLEANUP_DISABLED_TEXT, tooltip: CLEANUP_DISABLED_TOOLTIP };
      }
      return {
        [UNSCHEDULED_STATUS]: {
          text: sprintf(CLEANUP_UNSCHEDULED_TEXT, {
            time: this.timeFormatted(
              this.imageDetails.project.containerTagsExpirationPolicy.nextRunAt,
            ),
          }),
        },
        [SCHEDULED_STATUS]: { text: CLEANUP_SCHEDULED_TEXT, tooltip: CLEANUP_SCHEDULED_TOOLTIP },
        [ONGOING_STATUS]: { text: CLEANUP_ONGOING_TEXT, tooltip: CLEANUP_ONGOING_TOOLTIP },
        [UNFINISHED_STATUS]: { text: CLEANUP_UNFINISHED_TEXT, tooltip: CLEANUP_UNFINISHED_TOOLTIP },
      }[this.imageDetails?.expirationPolicyCleanupStatus];
    },
    deleteButtonDisabled() {
      return this.disabled || !this.imageDetails.userPermissions.destroyContainerRepository;
    },
    rootImageTooltip() {
      return !this.imageDetails.name ? ROOT_IMAGE_TOOLTIP : '';
    },
    imageName() {
      return getImageName(this.imageDetails);
    },
    formattedSize() {
      const { size } = this.imageDetails;
      return size ? numberToHumanSize(Number(size)) : null;
    },
    showBadgeProtected() {
      return Boolean(this.image?.protectionRuleExists);
    },
  },
  methods: {
    formatDate(date) {
      return formatDate(date, 'mmm d, yyyy HH:MM', true);
    },
  },
  i18n: {
    DELETE_IMAGE_TEXT,
    MORE_ACTIONS_TEXT,
    BADGE_PROTECTED_TOOLTIP_TEXT: s__(
      'ContainerRegistry|A protection rule exists for this container repository.',
    ),
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

    <template v-if="formattedSize" #metadata-size>
      <metadata-item
        icon="disk"
        :text="formattedSize"
        :text-tooltip="s__('ContainerRegistry|Includes both tagged and untagged images')"
        data-testid="image-size"
      />
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
        :text="createdText"
        size="xl"
        data-testid="created-and-visibility"
      />
    </template>

    <template v-if="containsLastPublishedAtDate" #metadata-last-published-at>
      <metadata-item
        icon="calendar"
        :text="lastPublishedAtText"
        size="xl"
        data-testid="last-published-at"
      />
    </template>

    <template #metadata-protection-rule-exists>
      <protected-badge
        v-if="showBadgeProtected"
        :tooltip-text="$options.i18n.BADGE_PROTECTED_TOOLTIP_TEXT"
      />
    </template>

    <template v-if="!deleteButtonDisabled" #right-actions>
      <gl-disclosure-dropdown
        category="tertiary"
        icon="ellipsis_v"
        placement="bottom-end"
        :toggle-text="$options.i18n.MORE_ACTIONS_TEXT"
        text-sr-only
        no-caret
      >
        <gl-disclosure-dropdown-item @action="$emit('delete')">
          <template #list-item>
            <span class="gl-text-red-500">
              {{ $options.i18n.DELETE_IMAGE_TEXT }}
            </span>
          </template>
        </gl-disclosure-dropdown-item>
      </gl-disclosure-dropdown>
    </template>
  </title-area>
</template>
