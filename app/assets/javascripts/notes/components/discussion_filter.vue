<script>
import $ from 'jquery';
import Icon from '~/vue_shared/components/icon.vue';
import { mapActions, mapGetters } from 'vuex';
import dropdown from '~/vue_shared/directives/dropdown.js'
import eventHub from '../event_hub';

export default {
  components: {
    Icon,
  },
  props: {
    filters: {
      type: Array,
      required: true
    },
    defaultValue: {
      type: Number,
      required: false
    },
  },
   directives: {
    dropdown,
  },

  data() {
    return { currentValue: this.defaultValue };
  },
  methods: {
    handleClick(e) {
      const { value } =  e.target;
      const newValue = parseInt(value, 10);

      if (newValue === this.currentValue) return;

      e.stopImmediatePropagation();
      this.currentValue = newValue;
      eventHub.$emit('notes.filter', this.currentValue);
    },
  },
  computed: {
    ...mapGetters([
      'discussionTabCounter',
    ]),
    currentFilter() {
      const selectedValue = this.currentValue ? this.currentValue : this.filters[0].value;
      return this.filters.find(filter => filter.value === selectedValue );
    }
  },
}
</script>

<template>
  <div
    v-if="discussionTabCounter > 0"
    class="line-resolve-all-container prepend-top-10 append-bottom-10 d-inline-flex">
    <button
      v-dropdown
      id="discussion-filter-dropdown"
      class="dropdown-toggle btn btn-default"
      data-toggle="dropdown"
      aria-expanded="false"
    >
      {{ currentFilter.title }} &nbsp;
      <Icon
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

