<script>
  import Icon from '~/vue_shared/components/icon.vue';
  /**
    Renders a slipt dropdown with
    an input that allows to search through the given
    array of options.
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
      },
      color: {
        required: false,
        validator: value => (
            ['primary', 'default', 'secondary', 'success', 'info', 'warning', 'danger'].indexOf(
              value,
            ) !== -1
          ),
        default: 'default',
      },
      mainActionLink: {
        type: String,
        required: false,
        default: null,
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
    },
    data() {
      return {
        filteredResults: this.items.slice(0, this.visibleItems - 1),
        filter: '',
      };
    },
    computed: {
      className() {
        return `btn btn-${this.color}`;
      },
    },
    methods: {
      onType() {},
    },
  };
</script>
<template>
  <div class="btn-group">
    <slot
      name="mainAction"
      :class-name="className">
      <button
        type="button"
        :class="className"
      >
        {{ title }}
      </button>
    </slot>

    <button
      type="button"
      :class="className"
      class="dropdown-toggle dropdown-toggle-split"
      data-toggle="dropdown"
      aria-haspopup="true"
      aria-expanded="false"
    >
      <i class="fa fa-caret-down"></i>
    </button>
    <div class="dropdown-menu dropdown-menu-right">
      <div class="position-relative">
        <input
          v-model="filter"
          type="search"
          placeholder="Filter"
          class="form-control"
        />
        <icon
          class="position-absolute search-icon"
          name="search" />
      </div>
      <template
        v-for="(result, i) in filteredResults"
      >
        <slot
          name="result"
          :result="result"
        >
          <li class="dropdown-item" :key="i">{{ result }}</li>
        </slot>
      </template>
    </div>
  </div>
</template>

<style>
  .dropdown-menu {
    padding: 8px;
  };
  .search-icon {
    top: 10px;
    right: 10px;
  }

  .dropdown-item {
    padding: 8px;
  }
</style>
