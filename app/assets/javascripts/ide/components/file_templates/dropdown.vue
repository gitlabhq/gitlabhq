<script>
import $ from 'jquery';
import { mapActions, mapState } from 'vuex';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';

export default {
  components: {
    DropdownButton,
    LoadingIcon,
  },
  props: {
    data: {
      type: Array,
      required: false,
      default: () => [],
    },
    label: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: null,
    },
    async: {
      type: Boolean,
      required: false,
      default: false,
    },
    searchable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    ...mapState('fileTemplates', ['templates', 'isLoading']),
    outputData() {
      return (this.async ? this.templates : this.data).filter(t => {
        if (!this.searchable) return true;

        return t.name.toLowerCase().indexOf(this.search.toLowerCase()) >= 0;
      });
    },
    showLoading() {
      return this.async ? this.isLoading : false;
    },
  },
  mounted() {
    $(this.$el).on('show.bs.dropdown', this.fetchTemplatesIfAsync);
  },
  beforeDestroy() {
    $(this.$el).off('show.bs.dropdown', this.fetchTemplatesIfAsync);
  },
  methods: {
    ...mapActions('fileTemplates', ['fetchTemplateTypes']),
    fetchTemplatesIfAsync() {
      if (this.async) {
        this.fetchTemplateTypes();
      }
    },
    clickItem(item) {
      this.$emit('click', item);
    },
  },
};
</script>

<template>
  <div class="dropdown">
    <dropdown-button
      :toggle-text="label"
    />
    <div class="dropdown-menu">
      <div
        v-if="title"
        class="dropdown-title"
      >
        {{ title }}
      </div>
      <div
        v-if="!showLoading && searchable"
        class="dropdown-input"
      >
        <input
          v-model="search"
          :placeholder="__('Filter...')"
          type="search"
          class="dropdown-input-field"
        />
      </div>
      <div class="dropdown-content">
        <loading-icon
          v-if="showLoading"
          size="2"
        />
        <ul v-else>
          <li
            v-for="(item, index) in outputData"
            :key="index"
          >
            <button
              type="button"
              @click="clickItem(item)"
            >
              {{ item.name }}
            </button>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
