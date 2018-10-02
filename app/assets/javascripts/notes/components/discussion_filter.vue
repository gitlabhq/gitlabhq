<script>
import $ from 'jquery';
import Icon from '~/vue_shared/components/icon.vue';
import { mapGetters } from 'vuex';
import eventHub from '../event_hub';

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
      'discussionTabCounter',
    ]),
    currentFilter() {
      if (!this.currentValue) return this.filters[0];
      return this.filters.find(filter => filter.value === this.currentValue);
    },
  },
  methods: {
    handleClick(e) {
      const { value } = e.target;
      const newValue = parseInt(value, 10);

      // close dropdown
      $('#discussion-filter-dropdown').dropdown('toggle');

      if (newValue === this.currentValue) return;

      e.stopImmediatePropagation();
      this.currentValue = newValue;
      eventHub.$emit('notes.filter', this.currentValue);
    },
  },
};
</script>

<template>
  <div
    v-if="discussionTabCounter > 0"
    class="prepend-top-10 d-inline-block">
    <button
      id="discussion-filter-dropdown"
      class="dropdown-toggle btn btn-default"
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
              :class="{ 'is-active': filter.value === currentFilter.value }"
              :value="filter.value"
              @click="handleClick"
            >
              {{ filter.title }}
            </button>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
