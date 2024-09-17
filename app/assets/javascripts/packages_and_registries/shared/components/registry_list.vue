<script>
import { GlButton, GlFormCheckbox, GlKeysetPagination } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'RegistryList',
  components: {
    GlButton,
    GlFormCheckbox,
    GlKeysetPagination,
  },
  props: {
    title: {
      type: String,
      default: '',
      required: false,
    },
    isLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
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
    disableDeleteButton() {
      return this.isLoading || this.selectedItems.length === 0;
    },
    selectedItems() {
      return this.items.filter(this.isSelected);
    },
    disabled() {
      return this.items.length === 0;
    },
    checked() {
      return this.items.every(this.isSelected);
    },
    indeterminate() {
      return !this.checked && this.items.some(this.isSelected);
    },
    label() {
      return this.checked ? __('Unselect all') : __('Select all');
    },
  },
  methods: {
    onChange(event) {
      this.items.forEach((item) => {
        const id = item[this.idProperty];
        this.selectedReferences = {
          ...this.selectedReferences,
          [id]: event,
        };
      });
    },
    selectItem(item) {
      const id = item[this.idProperty];
      this.selectedReferences = {
        ...this.selectedReferences,
        [id]: !this.selectedReferences[id],
      };
    },
    isSelected(item) {
      const id = item[this.idProperty];
      return this.selectedReferences[id];
    },
  },
  i18n: {
    deleteSelected: __('Delete selected'),
  },
};
</script>

<template>
  <div>
    <div v-if="!hiddenDelete" class="gl-mb-3 gl-mt-5 gl-flex gl-items-center gl-justify-between">
      <div class="gl-flex gl-items-center">
        <gl-form-checkbox
          class="gl-ml-2 gl-pt-2"
          :aria-label="label"
          :checked="checked"
          :disabled="disabled"
          :indeterminate="indeterminate"
          @change="onChange"
        />

        <p class="gl-mb-0 gl-font-bold">{{ title }}</p>
      </div>

      <gl-button
        :disabled="disableDeleteButton"
        category="secondary"
        variant="danger"
        @click="$emit('delete', selectedItems)"
      >
        {{ $options.i18n.deleteSelected }}
      </gl-button>
    </div>

    <ul class="gl-pl-0">
      <li v-for="(item, index) in items" :key="index" class="gl-list-none">
        <slot
          :select-item="selectItem"
          :is-selected="isSelected"
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
