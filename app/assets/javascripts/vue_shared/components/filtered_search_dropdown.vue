<script>
import $ from 'jquery';
import Icon from '~/vue_shared/components/icon.vue';
/**
 * Renders a split dropdown with
 * an input that allows to search through the given
 * array of options.
 */
export default {
  name: 'FilteredSearchDropdown',
  components: {
    Icon,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    buttonType: {
      required: false,
      validator: value =>
        ['primary', 'default', 'secondary', 'success', 'info', 'warning', 'danger'].indexOf(
          value,
        ) !== -1,
      default: 'default',
    },
    size: {
      required: false,
      type: String,
      default: 'sm',
    },
    items: {
      type: Array,
      required: true,
    },
    visibleItems: {
      type: Number,
      required: false,
      default: 5,
    },
    filterKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      filter: '',
    };
  },
  computed: {
    className() {
      return `btn btn-${this.buttonType} btn-${this.size}`;
    },
    filteredResults() {
      if (this.filter !== '') {
        return this.items.filter(
          item =>
            item[this.filterKey] &&
            item[this.filterKey].toLowerCase().includes(this.filter.toLowerCase()),
        );
      }

      return this.items.slice(0, this.visibleItems);
    },
  },
  mounted() {
    /**
     * Resets the filter every time the user closes the dropdown
     */
    $(this.$el)
      .on('shown.bs.dropdown', () => {
        this.$nextTick(() => this.$refs.searchInput.focus());
      })
      .on('hidden.bs.dropdown', () => {
        this.filter = '';
      });
  },
};
</script>
<template>
  <div class="dropdown">
    <div class="btn-group">
      <slot name="mainAction" :class-name="className">
        <button type="button" :class="className">{{ title }}</button>
      </slot>

      <button
        type="button"
        :class="className"
        class="dropdown-toggle dropdown-toggle-split"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
        aria-label="Expand dropdown"
      >
        <icon name="angle-down" :size="12" />
      </button>
      <div class="dropdown-menu dropdown-menu-right">
        <div class="dropdown-input">
          <input
            ref="searchInput"
            v-model="filter"
            type="search"
            placeholder="Filter"
            class="js-filtered-dropdown-input dropdown-input-field"
          />
          <icon class="dropdown-input-search" name="search" />
        </div>

        <div class="dropdown-content">
          <ul>
            <li v-for="(result, i) in filteredResults" :key="i" class="js-filtered-dropdown-result">
              <slot name="result" :result="result"> {{ result[filterKey] }} </slot>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>
