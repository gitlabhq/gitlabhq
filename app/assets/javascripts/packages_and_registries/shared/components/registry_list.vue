<script>
import { GlButton, GlFormCheckbox, GlKeysetPagination } from '@gitlab/ui';
import { filter } from 'lodash';
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
    showPagination() {
      return this.pagination.hasPreviousPage || this.pagination.hasNextPage;
    },
    disableDeleteButton() {
      return this.isLoading || filter(this.selectedReferences).length === 0;
    },
    selectedItems() {
      return this.items.filter(this.isSelected);
    },
    selectAll: {
      get() {
        return this.items.every(this.isSelected);
      },
      set(value) {
        this.items.forEach((item) => {
          const id = item[this.idProperty];
          this.$set(this.selectedReferences, id, value);
        });
      },
    },
  },
  methods: {
    selectItem(item) {
      const id = item[this.idProperty];
      this.$set(this.selectedReferences, id, !this.selectedReferences[id]);
    },
    isSelected(item) {
      const id = item[this.idProperty];
      return this.selectedReferences[id];
    },
  },
  i18n: {
    deleteSelected: __('Delete Selected'),
  },
};
</script>

<template>
  <div>
    <div
      v-if="!hiddenDelete"
      class="gl-display-flex gl-justify-content-space-between gl-mb-3 gl-align-items-center"
    >
      <gl-form-checkbox v-model="selectAll" class="gl-ml-2 gl-pt-2">
        <span class="gl-font-weight-bold">{{ title }}</span>
      </gl-form-checkbox>

      <gl-button
        :disabled="disableDeleteButton"
        category="secondary"
        variant="danger"
        @click="$emit('delete', selectedItems)"
      >
        {{ $options.i18n.deleteSelected }}
      </gl-button>
    </div>

    <div v-for="(item, index) in items" :key="index">
      <slot
        :select-item="selectItem"
        :is-selected="isSelected"
        :item="item"
        :first="index === 0"
      ></slot>
    </div>

    <div class="gl-display-flex gl-justify-content-center">
      <gl-keyset-pagination
        v-if="showPagination"
        v-bind="pagination"
        class="gl-mt-3"
        @prev="$emit('prev-page')"
        @next="$emit('next-page')"
      />
    </div>
  </div>
</template>
