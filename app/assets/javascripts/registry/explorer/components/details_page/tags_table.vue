<script>
import { GlTable, GlFormCheckbox, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { n__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import {
  LIST_KEY_TAG,
  LIST_KEY_IMAGE_ID,
  LIST_KEY_SIZE,
  LIST_KEY_LAST_UPDATED,
  LIST_KEY_ACTIONS,
  LIST_KEY_CHECKBOX,
  LIST_LABEL_TAG,
  LIST_LABEL_IMAGE_ID,
  LIST_LABEL_SIZE,
  LIST_LABEL_LAST_UPDATED,
  REMOVE_TAGS_BUTTON_TITLE,
  REMOVE_TAG_BUTTON_TITLE,
} from '../../constants/index';

export default {
  components: {
    GlTable,
    GlFormCheckbox,
    GlButton,
    ClipboardButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    tags: {
      type: Array,
      required: false,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDesktop: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  i18n: {
    REMOVE_TAGS_BUTTON_TITLE,
    REMOVE_TAG_BUTTON_TITLE,
  },
  data() {
    return {
      selectedItems: [],
    };
  },
  computed: {
    fields() {
      const tagClass = this.isDesktop ? 'w-25' : '';
      const tagInnerClass = this.isDesktop ? 'mw-m' : 'gl-justify-content-end';
      return [
        { key: LIST_KEY_CHECKBOX, label: '', class: 'gl-w-16' },
        {
          key: LIST_KEY_TAG,
          label: LIST_LABEL_TAG,
          class: `${tagClass} js-tag-column`,
          innerClass: tagInnerClass,
        },
        { key: LIST_KEY_IMAGE_ID, label: LIST_LABEL_IMAGE_ID },
        { key: LIST_KEY_SIZE, label: LIST_LABEL_SIZE },
        { key: LIST_KEY_LAST_UPDATED, label: LIST_LABEL_LAST_UPDATED },
        { key: LIST_KEY_ACTIONS, label: '' },
      ].filter(f => f.key !== LIST_KEY_CHECKBOX || this.isDesktop);
    },
    tagsNames() {
      return this.tags.map(t => t.name);
    },
    selectAllChecked() {
      return this.selectedItems.length === this.tags.length && this.tags.length > 0;
    },
  },
  watch: {
    tagsNames: {
      immediate: false,
      handler(tagsNames) {
        this.selectedItems = this.selectedItems.filter(t => tagsNames.includes(t));
      },
    },
  },
  methods: {
    formatSize(size) {
      return numberToHumanSize(size);
    },
    layers(layers) {
      return layers ? n__('%d layer', '%d layers', layers) : '';
    },
    onSelectAllChange() {
      if (this.selectAllChecked) {
        this.selectedItems = [];
      } else {
        this.selectedItems = this.tags.map(x => x.name);
      }
    },
    updateSelectedItems(name) {
      const delIndex = this.selectedItems.findIndex(x => x === name);

      if (delIndex > -1) {
        this.selectedItems.splice(delIndex, 1);
      } else {
        this.selectedItems.push(name);
      }
    },
  },
};
</script>

<template>
  <gl-table :items="tags" :fields="fields" :stacked="!isDesktop" show-empty :busy="isLoading">
    <template v-if="isDesktop" #head(checkbox)>
      <gl-form-checkbox
        data-testid="mainCheckbox"
        :checked="selectAllChecked"
        @change="onSelectAllChange"
      />
    </template>
    <template #head(actions)>
      <span class="gl-display-flex gl-justify-content-end">
        <gl-button
          v-gl-tooltip
          data-testid="bulkDeleteButton"
          :disabled="!selectedItems || selectedItems.length === 0"
          icon="remove"
          variant="danger"
          :title="$options.i18n.REMOVE_TAGS_BUTTON_TITLE"
          :aria-label="$options.i18n.REMOVE_TAGS_BUTTON_TITLE"
          @click="$emit('delete', selectedItems)"
        />
      </span>
    </template>

    <template #cell(checkbox)="{item}">
      <gl-form-checkbox
        data-testid="rowCheckbox"
        :checked="selectedItems.includes(item.name)"
        @change="updateSelectedItems(item.name)"
      />
    </template>
    <template #cell(name)="{item, field}">
      <div data-testid="rowName" :class="[field.innerClass, 'gl-display-flex']">
        <span
          v-gl-tooltip
          data-testid="rowNameText"
          :title="item.name"
          class="gl-text-overflow-ellipsis gl-overflow-hidden gl-white-space-nowrap"
        >
          {{ item.name }}
        </span>
        <clipboard-button
          v-if="item.location"
          data-testid="rowClipboardButton"
          :title="item.location"
          :text="item.location"
          css-class="btn-default btn-transparent btn-clipboard"
        />
      </div>
    </template>
    <template #cell(short_revision)="{value}">
      <span data-testid="rowShortRevision">
        {{ value }}
      </span>
    </template>
    <template #cell(total_size)="{item}">
      <span data-testid="rowSize">
        {{ formatSize(item.total_size) }}
        <template v-if="item.total_size && item.layers">
          &middot;
        </template>
        {{ layers(item.layers) }}
      </span>
    </template>
    <template #cell(created_at)="{value}">
      <span v-gl-tooltip data-testid="rowTime" :title="tooltipTitle(value)">
        {{ timeFormatted(value) }}
      </span>
    </template>
    <template #cell(actions)="{item}">
      <span class="gl-display-flex gl-justify-content-end">
        <gl-button
          data-testid="singleDeleteButton"
          :title="$options.i18n.REMOVE_TAG_BUTTON_TITLE"
          :aria-label="$options.i18n.REMOVE_TAG_BUTTON_TITLE"
          :disabled="!item.destroy_path"
          variant="danger"
          icon="remove"
          category="secondary"
          @click="$emit('delete', [item.name])"
        />
      </span>
    </template>

    <template #empty>
      <slot name="empty"></slot>
    </template>
    <template #table-busy>
      <slot name="loader"></slot>
    </template>
  </gl-table>
</template>
