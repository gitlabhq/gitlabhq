<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapActions, mapState } from 'vuex';
import Tracking from '~/tracking';
import frequentItemsMixin from './frequent_items_mixin';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlSearchBoxByType,
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
  methods: {
    ...mapActions(['setSearchQuery']),
  },
};
</script>

<template>
  <div class="search-input-container d-none d-sm-block">
    <gl-search-box-by-type
      v-model="searchQuery"
      :placeholder="translations.searchInputPlaceholder"
    />
  </div>
</template>
