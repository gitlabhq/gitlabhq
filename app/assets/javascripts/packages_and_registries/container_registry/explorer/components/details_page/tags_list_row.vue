<script>
import {
  GlFormCheckbox,
  GlTooltipDirective,
  GlSprintf,
  GlIcon,
  GlDisclosureDropdown,
  GlBadge,
  GlLink,
} from '@gitlab/ui';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';
import ListItem from '~/vue_shared/components/registry/list_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import {
  REMOVE_TAG_BUTTON_TITLE,
  DIGEST_LABEL,
  CREATED_AT_LABEL,
  PUBLISHED_DETAILS_ROW_TEXT,
  MANIFEST_DETAILS_ROW_TEST,
  CONFIGURATION_DETAILS_ROW_TEST,
  MISSING_MANIFEST_WARNING_TOOLTIP,
  NOT_AVAILABLE_TEXT,
  NOT_AVAILABLE_SIZE,
  MORE_ACTIONS_TEXT,
  COPY_IMAGE_PATH_TITLE,
  SIGNATURE_BADGE_TOOLTIP,
  DOCKER_MEDIA_TYPE,
  OCI_MEDIA_TYPE,
  DOCKER_MANIFEST_LIST_TOOLTIP,
  OCI_INDEX_TOOLTIP,
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
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
    CONFIGURATION_DETAILS_ROW_TEST,
    MISSING_MANIFEST_WARNING_TOOLTIP,
    MORE_ACTIONS_TEXT,
    COPY_IMAGE_PATH_TITLE,
    SIGNATURE_BADGE_TOOLTIP,
    DOCKER_MANIFEST_LIST_TOOLTIP,
    OCI_INDEX_TOOLTIP,
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
      return this.isMobile ? 'mw-s' : '';
    },
    shortDigest() {
      // remove sha256: from the string, and show only the first 7 char
      return this.tag.digest?.substring(7, 14) ?? NOT_AVAILABLE_TEXT;
    },
    publishDateTime() {
      return this.tag.publishedAt || this.tag.createdAt;
    },
    publishedDateTime() {
      return localeDateFormat.asDateTimeFull.format(this.publishDateTime);
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
    signatures() {
      const referrers = this.tag.referrers || [];
      // All referrers should be signatures, but we'll filter by signature artifact types as a sanity check.
      return referrers.filter(
        ({ artifactType }) => artifactType === 'application/vnd.dev.cosign.artifact.sig.v1+json',
      );
    },
    shouldDisplayLabelsIcon() {
      return this.tag.mediaType === DOCKER_MEDIA_TYPE || this.tag.mediaType === OCI_MEDIA_TYPE;
    },
    labelsIconTooltipText() {
      return this.tag.mediaType === DOCKER_MEDIA_TYPE
        ? this.$options.i18n.DOCKER_MANIFEST_LIST_TOOLTIP
        : this.$options.i18n.OCI_INDEX_TOOLTIP;
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
          class="gl-mr-2 gl-text-orange-500"
        />

        <gl-icon
          v-if="shouldDisplayLabelsIcon"
          v-gl-tooltip.d0="labelsIconTooltipText"
          name="labels"
          class="gl-mr-2"
          data-testid="labels-icon"
        />
      </div>
    </template>

    <template v-if="signatures.length" #left-after-toggle>
      <gl-badge v-gl-tooltip.d0="$options.i18n.SIGNATURE_BADGE_TOOLTIP" class="gl-ml-4">
        {{ s__('ContainerRegistry|Signed') }}
      </gl-badge>
    </template>

    <template #left-secondary>
      <span data-testid="size">
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
