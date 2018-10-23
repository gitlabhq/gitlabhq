<script>
import $ from 'jquery';
import Icon from '~/vue_shared/components/icon.vue';
import { mapGetters, mapActions } from 'vuex';

export default {
  components: {
    Icon,
  },
  props: {
    filters: {
      type: Array,
      required: true,
    },
    defaultValue: {
      type: Number,
      default: null,
      required: false,
    },
  },
  data() {
    return { currentValue: this.defaultValue };
  },
  computed: {
    ...mapGetters([
      'getNotesDataByProp',
    ]),
    currentFilter() {
      if (!this.currentValue) return this.filters[0];
      return this.filters.find(filter => filter.value === this.currentValue);
    },
  },
  methods: {
    ...mapActions(['filterDiscussion']),
    selectFilter(value) {
      const filter = parseInt(value, 10);

      // close dropdown
      $(this.$refs.dropdownToggle).dropdown('toggle');

      if (filter === this.currentValue) return;
      this.currentValue = filter;
      this.filterDiscussion({ path: this.getNotesDataByProp('discussionsPath'), filter });
    },
  },
};
</script>

<template>
  <div class="discussion-filter-container d-inline-block align-bottom">
    <button
      id="discussion-filter-dropdown"
      ref="dropdownToggle"
      class="btn btn-default"
      data-toggle="dropdown"
      aria-expanded="false"
    >
      {{ currentFilter.title }}
      <icon name="chevron-down" />
    </button>
    <div
      class="dropdown-menu dropdown-menu-selectable dropdown-menu-right"
      aria-labelledby="discussion-filter-dropdown">
      <div class="dropdown-content">
        <ul>
          <li
            v-for="filter in filters"
            :key="filter.value"
          >
            <button
              :class="{ 'is-active': filter.value === currentValue }"
              type="button"
              @click="selectFilter(filter.value)"
            >
              {{ filter.title }}
            </button>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
