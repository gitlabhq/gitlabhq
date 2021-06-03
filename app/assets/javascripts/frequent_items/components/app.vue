<script>
import { GlLoadingIcon } from '@gitlab/ui';
import AccessorUtilities from '~/lib/utils/accessor';
import {
  mapVuexModuleState,
  mapVuexModuleActions,
  mapVuexModuleGetters,
} from '~/lib/utils/vuex_module_mappers';
import { FREQUENT_ITEMS, STORAGE_KEY } from '../constants';
import eventHub from '../event_hub';
import { isMobile, updateExistingFrequentItem, sanitizeItem } from '../utils';
import FrequentItemsList from './frequent_items_list.vue';
import frequentItemsMixin from './frequent_items_mixin';
import FrequentItemsSearchInput from './frequent_items_search_input.vue';

export default {
  components: {
    FrequentItemsSearchInput,
    FrequentItemsList,
    GlLoadingIcon,
  },
  mixins: [frequentItemsMixin],
  inject: ['vuexModule'],
  props: {
    currentUserName: {
      type: String,
      required: true,
    },
    currentItem: {
      type: Object,
      required: true,
    },
    searchClass: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapVuexModuleState((vm) => vm.vuexModule, [
      'searchQuery',
      'isLoadingItems',
      'isFetchFailed',
      'items',
    ]),
    ...mapVuexModuleGetters((vm) => vm.vuexModule, ['hasSearchQuery']),
    translations() {
      return this.getTranslations(['loadingMessage', 'header']);
    },
  },
  created() {
    const { namespace, currentUserName, currentItem } = this;
    const storageKey = `${currentUserName}/${STORAGE_KEY[namespace]}`;

    this.setNamespace(namespace);
    this.setStorageKey(storageKey);

    if (currentItem.id) {
      this.logItemAccess(storageKey, currentItem);
    }

    eventHub.$on(`${this.namespace}-dropdownOpen`, this.dropdownOpenHandler);

    // As we init it through requestIdleCallback it could be that the dropdown is already open
    const namespaceDropdown = document.getElementById(`nav-${this.namespace}-dropdown`);
    if (namespaceDropdown && namespaceDropdown.classList.contains('show')) {
      this.dropdownOpenHandler();
    }
  },
  beforeDestroy() {
    eventHub.$off(`${this.namespace}-dropdownOpen`, this.dropdownOpenHandler);
  },
  methods: {
    ...mapVuexModuleActions((vm) => vm.vuexModule, [
      'setNamespace',
      'setStorageKey',
      'fetchFrequentItems',
    ]),
    dropdownOpenHandler() {
      if (this.searchQuery === '' || isMobile()) {
        this.fetchFrequentItems();
      }
    },
    logItemAccess(storageKey, unsanitizedItem) {
      const item = sanitizeItem(unsanitizedItem);

      if (!AccessorUtilities.isLocalStorageAccessSafe()) {
        return false;
      }

      // Check if there's any frequent items list set
      const storedRawItems = localStorage.getItem(storageKey);
      const storedFrequentItems = storedRawItems
        ? JSON.parse(storedRawItems)
        : [{ ...item, frequency: 1 }]; // No frequent items list set, set one up.

      // Check if item already exists in list
      const itemMatchIndex = storedFrequentItems.findIndex(
        (frequentItem) => frequentItem.id === item.id,
      );

      if (itemMatchIndex > -1) {
        storedFrequentItems[itemMatchIndex] = updateExistingFrequentItem(
          storedFrequentItems[itemMatchIndex],
          item,
        );
      } else {
        if (storedFrequentItems.length === FREQUENT_ITEMS.MAX_COUNT) {
          storedFrequentItems.shift();
        }

        storedFrequentItems.push({ ...item, frequency: 1 });
      }

      return localStorage.setItem(storageKey, JSON.stringify(storedFrequentItems));
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column gl-flex-align-items-stretch gl-h-full">
    <frequent-items-search-input
      :namespace="namespace"
      :class="searchClass"
      data-testid="frequent-items-search-input"
    />
    <gl-loading-icon
      v-if="isLoadingItems"
      :label="translations.loadingMessage"
      size="lg"
      class="loading-animation prepend-top-20"
      data-testid="loading"
    />
    <div v-if="!isLoadingItems && !hasSearchQuery" class="section-header" data-testid="header">
      {{ translations.header }}
    </div>
    <frequent-items-list
      v-if="!isLoadingItems"
      :items="items"
      :namespace="namespace"
      :has-search-query="hasSearchQuery"
      :is-fetch-failed="isFetchFailed"
      :matcher="searchQuery"
    />
  </div>
</template>
