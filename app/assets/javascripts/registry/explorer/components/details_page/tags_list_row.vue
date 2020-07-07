<script>
import { GlFormCheckbox, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { formatDate } from '~/lib/utils/datetime_utility';
import DeleteButton from '../delete_button.vue';
import ListItem from '../list_item.vue';
import DetailsRow from './details_row.vue';
import {
  REMOVE_TAG_BUTTON_TITLE,
  DIGEST_LABEL,
  CREATED_AT_LABEL,
  REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
  PUBLISHED_DETAILS_ROW_TEXT,
  MANIFEST_DETAILS_ROW_TEST,
  CONFIGURATION_DETAILS_ROW_TEST,
} from '../../constants/index';

export default {
  components: {
    GlSprintf,
    GlFormCheckbox,
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
    isDesktop: {
      type: Boolean,
      default: false,
      required: false,
    },
    selected: {
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
  },
  computed: {
    formattedSize() {
      return this.tag.total_size ? numberToHumanSize(this.tag.total_size) : '';
    },
    layers() {
      return this.tag.layers ? n__('%d layer', '%d layers', this.tag.layers) : '';
    },
    mobileClasses() {
      return this.isDesktop ? '' : 'mw-s';
    },
    shortDigest() {
      // remove sha256: from the string, and show only the first 7 char
      return this.tag.digest?.substring(7, 14);
    },
    publishedDate() {
      return formatDate(this.tag.created_at, 'isoDate');
    },
    publishedTime() {
      return formatDate(this.tag.created_at, 'hh:MM Z');
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
  },
};
</script>

<template>
  <list-item v-bind="$attrs" :selected="selected">
    <template #left-action>
      <gl-form-checkbox
        v-if="Boolean(tag.destroy_path)"
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
          css-class="btn-default btn-transparent btn-clipboard"
        />
      </div>
    </template>

    <template #left-secondary>
      <span data-testid="size">
        {{ formattedSize }}
        <template v-if="formattedSize && layers"
          >&middot;</template
        >
        {{ layers }}
      </span>
    </template>
    <template #right-primary>
      <span data-testid="time">
        <gl-sprintf :message="$options.i18n.CREATED_AT_LABEL">
          <template #timeInfo>
            <time-ago-tooltip :time="tag.created_at" />
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
        :disabled="!tag.destroy_path"
        :title="$options.i18n.REMOVE_TAG_BUTTON_TITLE"
        :tooltip-title="$options.i18n.REMOVE_TAG_BUTTON_DISABLE_TOOLTIP"
        :tooltip-disabled="Boolean(tag.destroy_path)"
        data-testid="single-delete-button"
        @delete="$emit('delete')"
      />
    </template>
    <template #details_published>
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
    <template #details_manifest_digest>
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
          css-class="btn-default btn-transparent btn-clipboard gl-p-0"
        />
      </details-row>
    </template>
    <template #details_configuration_digest>
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
          css-class="btn-default btn-transparent btn-clipboard gl-p-0"
        />
      </details-row>
    </template>
  </list-item>
</template>
