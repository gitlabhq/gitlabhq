<script>
import { GlFormCheckbox, GlTooltipDirective, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeleteButton from '../delete_button.vue';
import ListItem from '../list_item.vue';
import {
  REMOVE_TAG_BUTTON_TITLE,
  SHORT_REVISION_LABEL,
  CREATED_AT_LABEL,
  REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
} from '../../constants/index';

export default {
  components: {
    GlSprintf,
    GlFormCheckbox,
    DeleteButton,
    ListItem,
    ClipboardButton,
    TimeAgoTooltip,
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
    SHORT_REVISION_LABEL,
    CREATED_AT_LABEL,
    REMOVE_TAG_BUTTON_DISABLE_TOOLTIP,
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
      <span data-testid="short-revision">
        <gl-sprintf :message="$options.i18n.SHORT_REVISION_LABEL">
          <template #imageId>{{ tag.short_revision }}</template>
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
  </list-item>
</template>
