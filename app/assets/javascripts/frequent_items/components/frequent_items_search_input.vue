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
        property: 'navigation_top',
      });
      this.setSearchQuery(this.searchQuery);
    }, 500),
  },
  methods: {
    ...mapVuexModuleActions((vm) => vm.vuexModule, ['setSearchQuery']),
    trackFocus() {
      this.track('focus_input', {
        label: `${this.dropdownType}_dropdown_frequent_items_search_input`,
        property: 'navigation_top',
      });
    },
    trackBlur() {
      this.track('blur_input', {
        label: `${this.dropdownType}_dropdown_frequent_items_search_input`,
        property: 'navigation_top',
      });
    },
  },
};
</script>

<template>
  <div class="search-input-container">
    <gl-search-box-by-type
      v-model="searchQuery"
      :placeholder="translations.searchInputPlaceholder"
      @focus="trackFocus"
      @blur="trackBlur"
    />
  </div>
</template>
