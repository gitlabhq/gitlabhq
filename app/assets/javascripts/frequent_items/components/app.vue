<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import AccessorUtilities from '~/lib/utils/accessor';
import eventHub from '../event_hub';
import store from '../store/';
import { FREQUENT_ITEMS, STORAGE_KEY } from '../constants';
import { isMobile, updateExistingFrequentItem } from '../utils';
import FrequentItemsSearchInput from './frequent_items_search_input.vue';
import FrequentItemsList from './frequent_items_list.vue';
import frequentItemsMixin from './frequent_items_mixin';

export default {
  store,
  components: {
    LoadingIcon,
    FrequentItemsSearchInput,
    FrequentItemsList,
  },
  mixins: [frequentItemsMixin],
  props: {
    currentUserName: {
      type: String,
      required: true,
    },
    currentItem: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['searchQuery', 'isLoadingItems', 'isFetchFailed', 'items']),
    ...mapGetters(['hasSearchQuery']),
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
  },
  beforeDestroy() {
    eventHub.$off(`${this.namespace}-dropdownOpen`, this.dropdownOpenHandler);
  },
  methods: {
    ...mapActions(['setNamespace', 'setStorageKey', 'fetchFrequentItems']),
    dropdownOpenHandler() {
      if (this.searchQuery === '' || isMobile()) {
        this.fetchFrequentItems();
      }
    },
    logItemAccess(storageKey, item) {
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
        frequentItem => frequentItem.id === item.id,
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
  <div>
    <frequent-items-search-input
      :namespace="namespace"
    />
    <loading-icon
      v-if="isLoadingItems"
      :label="translations.loadingMessage"
      class="loading-animation prepend-top-20"
      size="2"
    />
    <div
      v-if="!isLoadingItems && !hasSearchQuery"
      class="section-header"
    >
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
