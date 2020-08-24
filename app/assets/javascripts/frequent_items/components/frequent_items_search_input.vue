<script>
import { debounce } from 'lodash';
import { mapActions } from 'vuex';
import { GlIcon } from '@gitlab/ui';
import eventHub from '../event_hub';
import frequentItemsMixin from './frequent_items_mixin';

export default {
  components: {
    GlIcon,
  },
  mixins: [frequentItemsMixin],
  data() {
    return {
      searchQuery: '',
    };
  },
  computed: {
    translations() {
      return this.getTranslations(['searchInputPlaceholder']);
    },
  },
  watch: {
    searchQuery: debounce(function debounceSearchQuery() {
      this.setSearchQuery(this.searchQuery);
    }, 500),
  },
  mounted() {
    eventHub.$on(`${this.namespace}-dropdownOpen`, this.setFocus);
  },
  beforeDestroy() {
    eventHub.$off(`${this.namespace}-dropdownOpen`, this.setFocus);
  },
  methods: {
    ...mapActions(['setSearchQuery']),
    setFocus() {
      this.$refs.search.focus();
    },
  },
};
</script>

<template>
  <div class="search-input-container d-none d-sm-block">
    <input
      ref="search"
      v-model="searchQuery"
      :placeholder="translations.searchInputPlaceholder"
      type="search"
      class="form-control"
    />
    <gl-icon v-if="!searchQuery" name="search" class="search-icon" />
  </div>
</template>
