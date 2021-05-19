<script>
import { GlFormCheckbox, GlTooltipDirective, GlSprintf, GlIcon } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
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
  REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
  PUBLISHED_DETAILS_ROW_TEXT,
  MANIFEST_DETAILS_ROW_TEST,
  CONFIGURATION_DETAILS_ROW_TEST,
  MISSING_MANIFEST_WARNING_TOOLTIP,
  NOT_AVAILABLE_TEXT,
  NOT_AVAILABLE_SIZE,
} from '../../constants/index';
import DeleteButton from '../delete_button.vue';

export default {
  components: {
    GlSprintf,
    GlFormCheckbox,
    GlIcon,
    DeleteButton,
    ListItem,
    ClipboardButton,
    TimeAgoTooltip,
    DetailsRow,
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
    REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
    PUBLISHED_DETAILS_ROW_TEXT,
    MANIFEST_DETAILS_ROW_TEST,
    CONFIGURATION_DETAILS_ROW_TEST,
    MISSING_MANIFEST_WARNING_TOOLTIP,
  },
  computed: {
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
    publishedDate() {
      return formatDate(this.tag.createdAt, 'isoDate');
    },
    publishedTime() {
      return formatDate(this.tag.createdAt, 'hh:MM Z');
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
    isInvalidTag() {
      return !this.tag.digest;
    },
    isCheckboxDisabled() {
      return this.isInvalidTag || this.disabled;
    },
    isDeleteDisabled() {
      return this.isInvalidTag || this.disabled || !this.tag.canDelete;
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs" :selected="selected" :disabled="disabled">
    <template #left-action>
      <gl-form-checkbox
        v-if="tag.canDelete"
        :disabled="isCheckboxDisabled"
        class="gl-m-0"
        :checked="selected"
        @change="$emit('select')"
      />
    </template>
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center">
        <div
          v-gl-tooltip="{ title: tag.name }"
          data-testid="name"
          class="gl-text-overflow-ellipsis gl-overflow-hidden gl-white-space-nowrap"
          :class="mobileClasses"
        >
          {{ tag.name }}
        </div>

        <clipboard-button
          v-if="tag.location"
          :title="tag.location"
          :text="tag.location"
          category="tertiary"
          :disabled="disabled"
        />

        <gl-icon
          v-if="isInvalidTag"
          v-gl-tooltip="{ title: $options.i18n.MISSING_MANIFEST_WARNING_TOOLTIP }"
          name="warning"
          class="gl-text-orange-500 gl-mb-2 gl-ml-2"
        />
      </div>
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
            <time-ago-tooltip :time="tag.createdAt" />
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
    <template #right-action>
      <delete-button
        :disabled="isDeleteDisabled"
        :title="$options.i18n.REMOVE_TAG_BUTTON_TITLE"
        :tooltip-title="$options.i18n.REMOVE_TAG_BUTTON_DISABLE_TOOLTIP"
        :tooltip-disabled="tag.canDelete"
        data-qa-selector="tag_delete_button"
        data-testid="single-delete-button"
        @delete="$emit('delete')"
      />
    </template>

    <template v-if="!isInvalidTag" #details-published>
      <details-row icon="clock" data-testid="published-date-detail">
        <gl-sprintf :message="$options.i18n.PUBLISHED_DETAILS_ROW_TEXT">
          <template #repositoryPath>
            <i>{{ tagLocation }}</i>
          </template>
          <template #time>
            {{ publishedTime }}
          </template>
          <template #date>
            {{ publishedDate }}
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
    <template v-if="!isInvalidTag" #details-configuration-digest>
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
  </list-item>
</template>
