<script>
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';

const findItem = (items, valueProp, value) => items.find(item => item[valueProp] === value);

export default {
  components: {
    DropdownButton,
    DropdownSearchInput,
    DropdownHiddenInput,
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
      type: [Object, String],
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
      default: searchQuery => item => item.name.toLowerCase().indexOf(searchQuery) > -1,
    },
  },
  data() {
    return {
      selectedItem: findItem(this.items, this.value),
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

      if (!this.selectedItem) {
        return this.placeholder;
      }

      return this.selectedItemLabel;
    },
    results() {
      if (!this.items) {
        return [];
      }

      return this.items.filter(this.searchFn(this.searchQuery));
    },
    selectedItemLabel() {
      return this.selectedItem && this.selectedItem[this.labelProperty];
    },
    selectedItemValue() {
      return (this.selectedItem && this.selectedItem[this.valueProperty]) || '';
    },
  },
  watch: {
    value(value) {
      this.selectedItem = findItem(this.items, this.valueProperty, value);
    },
  },
  methods: {
    select(item) {
      this.selectedItem = item;
      this.$emit('input', item[this.valueProperty]);
    },
  },
};
</script>

<template>
  <div>
    <div class="js-gcp-machine-type-dropdown dropdown">
      <dropdown-hidden-input :name="fieldName" :value="selectedItemValue" />
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
              <span class="js-empty-text menu-item">
                {{ emptyText }}
              </span>
            </li>
            <li v-for="item in results" :key="item.id">
              <button class="js-dropdown-item" type="button" @click.prevent="select(item)">
                <slot name="item" :item="item">
                  {{ item.name }}
                </slot>
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
    >
      {{ errorMessage }}
    </span>
  </div>
</template>
