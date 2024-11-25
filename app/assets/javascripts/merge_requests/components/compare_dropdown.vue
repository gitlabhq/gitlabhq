<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

export default {
  components: {
    GlCollapsibleListbox,
  },
  props: {
    staticData: {
      type: Array,
      required: false,
      default: () => [],
    },
    endpoint: {
      type: String,
      required: false,
      default: '',
    },
    default: {
      type: Object,
      required: true,
    },
    dropdownHeader: {
      type: String,
      required: true,
    },
    isProject: {
      type: Boolean,
      required: false,
      default: false,
    },
    inputId: {
      type: String,
      required: true,
    },
    inputName: {
      type: String,
      required: true,
    },
    toggleClass: {
      type: String,
      required: false,
      default: '',
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      current: this.default,
      selected: this.default.value,
      isLoading: false,
      data: this.staticData,
      searchStr: '',
    };
  },
  computed: {
    filteredData() {
      if (this.endpoint) return this.data;

      return this.data.filter(
        (d) => d.text.toLowerCase().indexOf(this.searchStr.toLowerCase()) >= 0,
      );
    },
  },
  watch: {
    default(newVal) {
      this.current = newVal;
      this.selected = newVal.value;
    },
  },
  methods: {
    async fetchData() {
      if (!this.endpoint) return;

      this.isLoading = true;

      try {
        const { data } = await axios.get(this.endpoint, {
          params: { search: this.searchStr },
        });

        if (this.isProject) {
          this.data = data.map((p) => ({
            value: `${p.id}`,
            text: p.full_path.replace(/^\//, ''),
            refsUrl: p.refs_url,
          }));
        } else {
          this.data = data.Branches.map((d) => ({
            value: d,
            text: d,
          }));
        }

        this.isLoading = false;
      } catch {
        createAlert({
          message: __('Error fetching data. Please try again.'),
          primaryButton: { text: __('Try again'), clickHandler: () => this.fetchData() },
        });
      }
    },
    searchData: debounce(function searchData(search) {
      this.searchStr = search;
      this.fetchData();
    }, 500),
    selectItem(id) {
      this.current = this.data.find((d) => d.value === id);

      this.$emit('selected', this.current);
    },
  },
};
</script>

<template>
  <div>
    <input
      :id="inputId"
      type="hidden"
      :value="current.value"
      :name="inputName"
      data-testid="target-project-input"
    />
    <gl-collapsible-listbox
      v-model="selected"
      :items="filteredData"
      :toggle-text="current.text || dropdownHeader"
      :header-text="dropdownHeader"
      :searching="isLoading"
      :disabled="disabled"
      searchable
      class="dropdown-target-project gl-w-full"
      :toggle-class="['mr-compare-dropdown', toggleClass]"
      @shown="fetchData"
      @search="searchData"
      @select="selectItem"
    />
  </div>
</template>
