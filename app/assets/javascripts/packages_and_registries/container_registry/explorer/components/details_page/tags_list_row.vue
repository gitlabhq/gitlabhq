<script>
import {
  GlFormCheckbox,
  GlTooltipDirective,
  GlSprintf,
  GlIcon,
  GlDisclosureDropdown,
  GlBadge,
  GlLink,
  GlPopover,
} from '@gitlab/ui';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  REMOVE_TAG_BUTTON_TITLE,
  DIGEST_LABEL,
  CREATED_AT_LABEL,
  PUBLISHED_DETAILS_ROW_TEXT,
  MANIFEST_DETAILS_ROW_TEST,
  MANIFEST_MEDIA_TYPE_ROW_TEXT,
  CONFIGURATION_DETAILS_ROW_TEST,
  MISSING_MANIFEST_WARNING_TOOLTIP,
  NOT_AVAILABLE_TEXT,
  NOT_AVAILABLE_SIZE,
  MORE_ACTIONS_TEXT,
  COPY_IMAGE_PATH_TITLE,
  SIGNATURE_BADGE_TOOLTIP,
  DOCKER_MEDIA_TYPE,
  OCI_MEDIA_TYPE,
} from '../../constants/index';
import SignatureDetailsModal from './signature_details_modal.vue';

export default {
  components: {
    GlSprintf,
    GlFormCheckbox,
    GlIcon,
    GlDisclosureDropdown,
    GlBadge,
    GlLink,
    ListItem,
    ClipboardButton,
    TimeAgoTooltip,
    DetailsRow,
    SignatureDetailsModal,
    GlPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    tag: {
      type: Object,
      required: true,
    },
    isMobile: {
      type: Boolean,
      default: true,
      required: false,
    },
    selected: {
      type: Boolean,
      default: false,
      required: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  i18n: {
    REMOVE_TAG_BUTTON_TITLE,
    DIGEST_LABEL,
    CREATED_AT_LABEL,
    PUBLISHED_DETAILS_ROW_TEXT,
    MANIFEST_DETAILS_ROW_TEST,
    MANIFEST_MEDIA_TYPE_ROW_TEXT,
    CONFIGURATION_DETAILS_ROW_TEST,
    MISSING_MANIFEST_WARNING_TOOLTIP,
    MORE_ACTIONS_TEXT,
    COPY_IMAGE_PATH_TITLE,
    SIGNATURE_BADGE_TOOLTIP,
  },
  data() {
    return {
      selectedDigest: null,
    };
  },
  computed: {
    items() {
      return [
        {
          text: this.$options.i18n.REMOVE_TAG_BUTTON_TITLE,
          extraAttrs: {
            class: '!gl-text-red-500',
            'data-testid': 'single-delete-button',
          },
          action: () => {
            this.$emit('delete');
          },
        },
      ];
    },
    formattedSize() {
      return this.tag.totalSize
        ? numberToHumanSize(Number(this.tag.totalSize))
        : NOT_AVAILABLE_SIZE;
    },
    layers() {
      return this.tag.layers ? n__('%d layer', '%d layers', this.tag.layers) : '';
    },
    mobileClasses() {
      return this.isMobile ? 'gl-max-w-20' : '';
    },
    shortDigest() {
      // remove sha256: from the string, and show only the first 7 char
      return this.tag.digest?.substring(7, 14) ?? NOT_AVAILABLE_TEXT;
    },
    publishDateTime() {
      return this.tag.publishedAt || this.tag.createdAt;
    },
    publishedDateTime() {
      return localeDateFormat.asDateTimeFull.format(newDate(this.publishDateTime));
    },
    formattedRevision() {
      // to be removed when API response is adjusted
      // see https://gitlab.com/gitlab-org/gitlab/-/issues/225324
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `sha256:${this.tag.revision}`;
    },
    tagLocation() {
      return this.tag.path?.replace(`:${this.tag.name}`, '');
    },
    isEmptyRevision() {
      return this.tag.revision === '';
    },
    isInvalidTag() {
      return !this.tag.digest;
    },
    showConfigDigest() {
      return !this.isInvalidTag && !this.isEmptyRevision;
    },
    showManifestMediaType() {
      return !this.isInvalidTag && this.tag.mediaType;
    },
    signatures() {
      const referrers = this.tag.referrers || [];
      // All referrers should be signatures, but we'll filter by signature artifact types as a sanity check.
      return referrers.filter(
        ({ artifactType }) => artifactType === 'application/vnd.dev.cosign.artifact.sig.v1+json',
      );
    },
    isDockerOrOciMediaType() {
      return this.tag.mediaType === DOCKER_MEDIA_TYPE || this.tag.mediaType === OCI_MEDIA_TYPE;
    },
    isProtected() {
      return (
        (this.tag.protection?.minimumAccessLevelForDelete != null ||
          this.tag.protection?.minimumAccessLevelForPush != null) &&
        this.glFeatures.containerRegistryProtectedTags
      );
    },
    tagRowId() {
      return `${this.tag.name}_badge`;
    },
    accessLevelForDelete() {
      return this.tag.protection?.minimumAccessLevelForDelete;
    },
    accessLevelForPush() {
      return this.tag.protection?.minimumAccessLevelForPush;
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs" :selected="selected" :disabled="disabled">
    <template #left-action>
      <gl-form-checkbox
        v-if="tag.userPermissions.destroyContainerRepositoryTag"
        :disabled="disabled"
        class="gl-m-0"
        :checked="selected"
        @change="$emit('select')"
      />
    </template>
    <template #left-primary>
      <div class="gl-flex gl-items-center">
        <div
          v-gl-tooltip="tag.name"
          data-testid="name"
          class="gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap"
          :class="mobileClasses"
        >
          {{ tag.name }}
        </div>

        <template v-if="isProtected">
          <gl-badge
            :id="tagRowId"
            boundary="viewport"
            class="gl-ml-4"
            data-testid="protected-badge"
          >
            {{ __('protected') }}
          </gl-badge>
          <gl-popover :target="tagRowId" data-testid="protected-popover">
            <strong>{{ s__('ContainerRegistry|This tag is protected') }}</strong>
            <br />
            <br />
            <strong>{{ s__('ContainerRegistry|Minimum role to push: ') }}</strong>
            {{ accessLevelForPush }}
            <strong>{{ s__('ContainerRegistry|Minimum role to delete: ') }}</strong>
            {{ accessLevelForDelete }}
          </gl-popover>
        </template>

        <clipboard-button
          v-if="tag.location"
          :title="$options.i18n.COPY_IMAGE_PATH_TITLE"
          :text="tag.location"
          category="tertiary"
          :disabled="disabled"
          class="gl-ml-2"
          size="small"
        />

        <gl-icon
          v-if="isInvalidTag"
          v-gl-tooltip.d0="$options.i18n.MISSING_MANIFEST_WARNING_TOOLTIP"
          name="warning"
          class="gl-mr-2"
          variant="warning"
        />
      </div>
    </template>

    <template v-if="signatures.length" #left-after-toggle>
      <gl-badge
        v-gl-tooltip.d0="$options.i18n.SIGNATURE_BADGE_TOOLTIP"
        class="gl-ml-4"
        data-testid="signed-badge"
      >
        {{ s__('ContainerRegistry|Signed') }}
      </gl-badge>
    </template>

    <template #left-secondary>
      <gl-badge v-if="isDockerOrOciMediaType" data-testid="index-badge">
        {{ s__('ContainerRegistry|index') }}
      </gl-badge>

      <span v-else data-testid="size">
        {{ formattedSize }}
        <template v-if="formattedSize && layers">&middot;</template>
        {{ layers }}
      </span>
    </template>
    <template #right-primary>
      <span data-testid="time">
        <gl-sprintf :message="$options.i18n.CREATED_AT_LABEL">
          <template #timeInfo>
            <time-ago-tooltip :time="publishDateTime" />
          </template>
        </gl-sprintf>
      </span>
    </template>
    <template #right-secondary>
      <span data-testid="digest">
        <gl-sprintf :message="$options.i18n.DIGEST_LABEL">
          <template #imageId>{{ shortDigest }}</template>
        </gl-sprintf>
      </span>
    </template>
    <template v-if="tag.userPermissions.destroyContainerRepositoryTag" #right-action>
      <gl-disclosure-dropdown
        :disabled="disabled"
        icon="ellipsis_v"
        :toggle-text="$options.i18n.MORE_ACTIONS_TEXT"
        :text-sr-only="true"
        category="tertiary"
        no-caret
        placement="bottom-end"
        :class="{ 'gl-pointer-events-none gl-opacity-0': disabled }"
        data-testid="additional-actions"
        :items="items"
      />
    </template>

    <template v-if="!isInvalidTag" #details-published>
      <details-row icon="clock" padding="gl-py-3" data-testid="published-date-detail">
        <gl-sprintf :message="$options.i18n.PUBLISHED_DETAILS_ROW_TEXT">
          <template #repositoryPath>
            <i>{{ tagLocation }}</i>
          </template>
          <template #dateTime>
            {{ publishedDateTime }}
          </template>
        </gl-sprintf>
      </details-row>
    </template>
    <template v-if="!isInvalidTag" #details-manifest-digest>
      <details-row icon="log" data-testid="manifest-detail">
        <gl-sprintf :message="$options.i18n.MANIFEST_DETAILS_ROW_TEST">
          <template #digest>
            {{ tag.digest }}
          </template>
        </gl-sprintf>
        <clipboard-button
          v-if="tag.digest"
          :title="tag.digest"
          :text="tag.digest"
          category="tertiary"
          size="small"
          :disabled="disabled"
        />
      </details-row>
    </template>
    <template v-if="showManifestMediaType" #details-manifest-media-type>
      <details-row icon="media" data-testid="manifest-media-type">
        <gl-sprintf :message="$options.i18n.MANIFEST_MEDIA_TYPE_ROW_TEXT">
          <template #mediaType>
            {{ tag.mediaType }}
          </template>
        </gl-sprintf>
      </details-row>
    </template>
    <template v-if="showConfigDigest" #details-configuration-digest>
      <details-row icon="cloud-gear" data-testid="configuration-detail">
        <gl-sprintf :message="$options.i18n.CONFIGURATION_DETAILS_ROW_TEST">
          <template #digest>
            {{ formattedRevision }}
          </template>
        </gl-sprintf>
        <clipboard-button
          v-if="formattedRevision"
          :title="formattedRevision"
          :text="formattedRevision"
          category="tertiary"
          size="small"
          :disabled="disabled"
        />
      </details-row>
    </template>

    <template v-if="signatures.length" #details-signatures>
      <details-row
        v-for="({ digest }, index) in signatures"
        :key="index"
        icon="pencil"
        data-testid="signatures-detail"
      >
        <div class="gl-flex">
          <span class="gl-mr-3 gl-grow gl-basis-0 gl-truncate">
            <gl-sprintf :message="s__('ContainerRegistry|Signature digest: %{digest}')">
              <template #digest>{{ digest }}</template>
            </gl-sprintf>
          </span>

          <gl-link @click="selectedDigest = digest">
            {{ __('View details') }}
          </gl-link>
        </div>
      </details-row>

      <signature-details-modal
        :visible="Boolean(selectedDigest)"
        :digest="selectedDigest"
        @close="selectedDigest = null"
      />
    </template>
  </list-item>
</template>
