<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import { mapVuexModuleActions, mapVuexModuleState } from '~/lib/utils/vuex_module_mappers';
import Tracking from '~/tracking';
import frequentItemsMixin from './frequent_items_mixin';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlSearchBoxByType,
  },
  mixins: [frequentItemsMixin, trackingMixin],
  inject: ['vuexModule'],
  data() {
    return {
      searchQuery: '',
    };
  },
  computed: {
    ...mapVuexModuleState((vm) => vm.vuexModule, ['dropdownType']),
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
    ...mapVuexModuleActions((vm) => vm.vuexModule, ['setSearchQuery']),
  },
};
</script>

<template>
  <div class="search-input-container">
    <gl-search-box-by-type
      v-model="searchQuery"
      :placeholder="translations.searchInputPlaceholder"
    />
  </div>
</template>
