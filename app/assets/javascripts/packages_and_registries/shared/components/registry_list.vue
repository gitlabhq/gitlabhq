<script>
import { GlButton, GlFormCheckbox, GlKeysetPagination, GlSprintf } from '@gitlab/ui';
import { __, n__ } from '~/locale';

export default {
  name: 'RegistryList',
  components: {
    GlButton,
    GlFormCheckbox,
    GlKeysetPagination,
    GlSprintf,
  },
  props: {
    hiddenDelete: {
      type: Boolean,
      default: false,
      required: false,
    },
    pagination: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    unSelectableItemIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    idProperty: {
      type: String,
      required: false,
      default: 'id',
    },
  },
  data() {
    return {
      selectedReferences: {},
    };
  },
  computed: {
    containsSelectedItems() {
      return this.selectedItems.length > 0;
    },
    selectableItems() {
      if (this.unSelectableItemIds.length === 0) {
        return this.items;
      }
      return this.items.filter((item) => !this.unSelectableItemIds.includes(this.getItemId(item)));
    },
    selectedItems() {
      return this.items.filter(this.isSelected);
    },
    selectableItemIds() {
      return this.selectableItems.map((item) => item[this.idProperty]);
    },
    disabled() {
      return this.selectableItems.length === 0;
    },
    checked() {
      return !this.disabled && this.selectableItems.every(this.isSelected);
    },
    indeterminate() {
      return !this.checked && this.items.some(this.isSelected);
    },
    selectAllLabel() {
      return this.checked ? __('Clear all') : __('Select all');
    },
    selectedCountMessage() {
      return n__(
        'PackageRegistry|%{count} selected',
        'PackageRegistry|%{count} selected',
        this.selectedItems.length,
      );
    },
  },
  methods: {
    handleSelectAllChange(event) {
      this.selectableItems.forEach((item) => {
        const id = this.getItemId(item);
        this.selectedReferences = {
          ...this.selectedReferences,
          [id]: event,
        };
      });
    },
    getItemId(item) {
      return item[this.idProperty];
    },
    selectItem(item) {
      const id = this.getItemId(item);
      this.selectedReferences = {
        ...this.selectedReferences,
        [id]: !this.selectedReferences[id],
      };
    },
    isSelected(item) {
      const id = this.getItemId(item);
      return this.selectedReferences[id];
    },
    isSelectable(item) {
      return this.selectableItemIds.includes(this.getItemId(item));
    },
  },
  i18n: {
    deleteSelected: __('Delete selected'),
  },
};
</script>

<template>
  <div>
    <div v-if="!hiddenDelete" class="gl-my-3 gl-flex gl-flex-grow gl-items-baseline gl-gap-2">
      <gl-form-checkbox
        class="gl-ml-2 gl-pt-2"
        :checked="checked"
        :disabled="disabled"
        :indeterminate="indeterminate"
        @change="handleSelectAllChange"
      >
        {{ selectAllLabel }}
      </gl-form-checkbox>

      <span v-if="containsSelectedItems">|</span>
      <div
        v-if="containsSelectedItems"
        class="gl-flex gl-flex-grow gl-items-baseline gl-justify-between gl-gap-1"
      >
        <span data-testid="selected-count">
          <gl-sprintf :message="selectedCountMessage">
            <template #count>
              <strong>{{ selectedItems.length }}</strong>
            </template>
          </gl-sprintf>
        </span>
        <gl-button variant="danger" size="small" @click="$emit('delete', selectedItems)">
          {{ $options.i18n.deleteSelected }}
        </gl-button>
      </div>
    </div>

    <ul class="gl-pl-0">
      <li v-for="(item, index) in items" :key="getItemId(item)" class="gl-list-none">
        <slot
          :select-item="selectItem"
          :is-selected="isSelected"
          :is-selectable="isSelectable"
          :item="item"
          :first="!hiddenDelete && index === 0"
        ></slot>
      </li>
    </ul>

    <div class="gl-flex gl-justify-center">
      <gl-keyset-pagination
        v-bind="pagination"
        class="gl-mt-3"
        @prev="$emit('prev-page')"
        @next="$emit('next-page')"
      />
    </div>
  </div>
</template>
