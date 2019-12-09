<script>
import { GlIcon } from '@gitlab/ui';
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';

const toArray = value => [].concat(value);
const itemsProp = (items, prop) => items.map(item => item[prop]);
const defaultSearchFn = (searchQuery, labelProp) => item =>
  item[labelProp].toLowerCase().indexOf(searchQuery) > -1;

export default {
  components: {
    DropdownButton,
    DropdownSearchInput,
    DropdownHiddenInput,
    GlIcon,
  },
  props: {
    fieldName: {
      type: String,
      required: false,
      default: '',
    },
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
    defaultValue: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: [Object, Array, String],
      required: false,
      default: () => null,
    },
    labelProperty: {
      type: String,
      required: false,
      default: 'name',
    },
    valueProperty: {
      type: String,
      required: false,
      default: 'value',
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    loadingText: {
      type: String,
      required: false,
      default: '',
    },
    disabledText: {
      type: String,
      required: false,
      default: '',
    },
    hasErrors: {
      type: Boolean,
      required: false,
      default: false,
    },
    multiple: {
      type: Boolean,
      required: false,
      default: false,
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
    searchFieldPlaceholder: {
      type: String,
      required: false,
      default: '',
    },
    emptyText: {
      type: String,
      required: false,
      default: '',
    },
    searchFn: {
      type: Function,
      required: false,
      default: defaultSearchFn,
    },
  },
  data() {
    return {
      searchQuery: '',
    };
  },
  computed: {
    toggleText() {
      if (this.loading && this.loadingText) {
        return this.loadingText;
      }

      if (this.disabled && this.disabledText) {
        return this.disabledText;
      }

      if (!this.selectedItems.length) {
        return this.placeholder;
      }

      return this.selectedItemsLabels;
    },
    results() {
      return this.getItemsOrEmptyList().filter(this.searchFn(this.searchQuery, this.labelProperty));
    },
    selectedItems() {
      const valueProp = this.valueProperty;
      const valueList = toArray(this.value);
      const items = this.getItemsOrEmptyList();

      return items.filter(item => valueList.some(value => item[valueProp] === value));
    },
    selectedItemsLabels() {
      return itemsProp(this.selectedItems, this.labelProperty).join(', ');
    },
    selectedItemsValues() {
      return itemsProp(this.selectedItems, this.valueProperty).join(', ');
    },
  },
  methods: {
    getItemsOrEmptyList() {
      return this.items || [];
    },
    selectSingle(item) {
      this.$emit('input', item[this.valueProperty]);
    },
    selectMultiple(item) {
      const value = toArray(this.value);
      const itemValue = item[this.valueProperty];
      const itemValueIndex = value.indexOf(itemValue);

      if (itemValueIndex > -1) {
        value.splice(itemValueIndex, 1);
      } else {
        value.push(itemValue);
      }

      this.$emit('input', value);
    },
    isSelected(item) {
      return this.selectedItems.includes(item);
    },
  },
};
</script>

<template>
  <div>
    <div class="js-gcp-machine-type-dropdown dropdown">
      <dropdown-hidden-input :name="fieldName" :value="selectedItemsValues" />
      <dropdown-button
        :class="{ 'border-danger': hasErrors }"
        :is-disabled="disabled"
        :is-loading="loading"
        :toggle-text="toggleText"
      />
      <div class="dropdown-menu dropdown-select">
        <dropdown-search-input v-model="searchQuery" :placeholder-text="searchFieldPlaceholder" />
        <div class="dropdown-content">
          <ul>
            <li v-if="!results.length">
              <span class="js-empty-text menu-item">{{ emptyText }}</span>
            </li>
            <li v-for="item in results" :key="item.id">
              <button
                v-if="multiple"
                class="js-dropdown-item d-flex align-items-center"
                type="button"
                @click.stop.prevent="selectMultiple(item)"
              >
                <gl-icon
                  :class="[{ invisible: !isSelected(item) }, 'mr-1']"
                  name="mobile-issue-close"
                />
                <slot name="item" :item="item">{{ item.name }}</slot>
              </button>
              <button
                v-else
                class="js-dropdown-item"
                type="button"
                @click.prevent="selectSingle(item)"
              >
                <slot name="item" :item="item">{{ item.name }}</slot>
              </button>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <span
      v-if="hasErrors && errorMessage"
      :class="[
        'form-text js-eks-dropdown-error-message',
        {
          'text-danger': hasErrors,
          'text-muted': !hasErrors,
        },
      ]"
      >{{ errorMessage }}</span
    >
  </div>
</template>
