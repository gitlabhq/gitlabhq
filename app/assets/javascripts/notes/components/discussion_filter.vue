<script>
import Icon from '~/vue_shared/components/icon.vue';
import { mapGetters } from 'vuex';
import dropdown from '~/vue_shared/directives/dropdown';
import eventHub from '../event_hub';

export default {
  components: {
    Icon,
  },
  directives: {
    dropdown,
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
      const selectedValue = this.currentValue ? this.currentValue : this.filters[0].value;
      return this.filters.find(filter => filter.value === selectedValue);
    },
  },
  methods: {
    handleClick(e) {
      const { value } = e.target;
      const newValue = parseInt(value, 10);

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
    class="prepend-top-10 append-bottom-10 append-right-4 d-inline-flex">
    <button
      v-dropdown
      id="discussion-filter-dropdown"
      class="dropdown-toggle btn btn-default"
      data-toggle="dropdown"
      aria-expanded="false"
    >
      <span class="append-right-4">{{ currentFilter.title }}</span>
      <icon
        :size="12"
        name="angle-down"
      />
    </button>
    <div
      class="dropdown-menu dropdown-menu-selectable"
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
