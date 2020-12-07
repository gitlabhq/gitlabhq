<script>
import { debounce } from 'lodash';
import { mapActions, mapState } from 'vuex';
import { GlIcon } from '@gitlab/ui';
import eventHub from '../event_hub';
import frequentItemsMixin from './frequent_items_mixin';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlIcon,
  },
  mixins: [frequentItemsMixin, trackingMixin],
  data() {
    return {
      searchQuery: '',
    };
  },
  computed: {
    ...mapState(['dropdownType']),
    translations() {
      return this.getTranslations(['searchInputPlaceholder']);
    },
  },
  watch: {
    searchQuery: debounce(function debounceSearchQuery() {
      this.track('type_search_query', {
        label: `${this.dropdownType}_dropdown_frequent_items_search_input`,
      });
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
