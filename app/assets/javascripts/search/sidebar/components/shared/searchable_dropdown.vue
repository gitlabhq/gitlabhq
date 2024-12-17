<script>
import { GlCollapsibleListbox, GlAvatar } from '@gitlab/ui';
import { debounce } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __, s__, n__ } from '~/locale';
import { ANY_OPTION } from '../../constants';

export default {
  name: 'SearchableDropdown',
  components: {
    GlAvatar,
    GlCollapsibleListbox,
  },
  directives: {
    SafeHtml,
  },
  i18n: {
    frequentlySearched: __('Frequently searched'),
    availableGroups: s__('GlobalSearch|All available groups'),
    nothingFound: s__('GlobalSearch|Nothing found…'),
    reset: s__('GlobalSearch|Reset'),
    itemsFound(count) {
      return n__('%d item found', '%d items found', count);
    },
  },
  props: {
    headerText: {
      type: String,
      required: false,
      default: "__('Filter')",
    },
    name: {
      type: String,
      required: false,
      default: 'name',
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    selectedItem: {
      type: Object,
      required: true,
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    frequentItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    searchHandler: {
      type: Function,
      required: true,
    },
    labelId: {
      type: String,
      required: false,
      default: 'labelId',
    },
  },
  data() {
    return {
      searchText: '',
      hasBeenOpened: false,
      showableItems: [],
      searchInProgress: false,
    };
  },
  watch: {
    items() {
      if (this.searchText === '') {
        this.showableItems = this.defaultItems();
      }
    },
  },
  created() {
    this.showableItems = this.defaultItems();
  },
  methods: {
    defaultItems() {
      const frequentItems = this.convertItemsFormat([...this.frequentItems]);
      const nonFrequentItems = this.convertItemsFormat([
        ...this.uniqueItems(this.items, this.frequentItems),
      ]);

      return [
        {
          text: '',
          options: [
            {
              value: ANY_OPTION.name,
              text: ANY_OPTION.name,
              ...ANY_OPTION,
            },
          ],
        },
        {
          text: this.$options.i18n.frequentlySearched,
          options: frequentItems,
        },
        {
          text: this.$options.i18n.availableGroups,
          options: nonFrequentItems,
        },
      ].filter((group) => {
        return group.options.length > 0;
      });
    },
    search(search) {
      this.searchText = search;
      this.searchInProgress = true;

      if (search !== '') {
        debounce(() => {
          this.searchHandler(this.searchText);
          this.showableItems = this.convertItemsFormat([...this.items]);
        }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS)();

        return;
      }

      this.showableItems = this.defaultItems();
    },
    openDropdown() {
      if (!this.hasBeenOpened) {
        this.hasBeenOpened = true;
        this.$emit('first-open');
      }
    },
    resetDropdown() {
      this.$emit('change', ANY_OPTION);
    },
    convertItemsFormat(items) {
      return items.map((item) => ({ value: item.id, text: item.full_name, ...item }));
    },
    truncatedNamespace(item) {
      const itemDuplicat = { ...item };
      const namespaceWithFallback = itemDuplicat.name_with_namespace
        ? itemDuplicat.name_with_namespace
        : itemDuplicat.full_name;

      return truncateNamespace(namespaceWithFallback);
    },
    highlightedItemName(item) {
      return highlight(item.name, item.searchText);
    },
    onSelectGroup(selected) {
      if (selected === ANY_OPTION.name) {
        this.$emit('change', ANY_OPTION);
        return;
      }

      const flatShowableItems = [...this.frequentItems, ...this.items];
      const newSelectedItem = flatShowableItems.find((item) => item.id === selected);
      this.$emit('change', newSelectedItem);
    },
    uniqueItems(allItems, frequentItems) {
      return allItems.filter((item) => {
        const itemNotIdentical = frequentItems.some((fitem) => fitem.id === item.id);
        return Boolean(!itemNotIdentical);
      });
    },
  },
  ANY_OPTION,
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-collapsible-listbox
    :items="showableItems"
    :header-text="headerText"
    :toggle-text="selectedItem[name]"
    :no-results-text="$options.i18n.nothingFound"
    :selected="selectedItem.id"
    :searching="loading"
    :reset-button-label="$options.i18n.reset"
    :toggle-aria-labelled-by="labelId"
    fluid-width
    searchable
    block
    @shown="openDropdown"
    @search="search"
    @select="onSelectGroup"
    @reset="resetDropdown"
  >
    <template #search-summary-sr-only>
      {{ $options.i18n.itemsFound(showableItems.length) }}
    </template>
    <template #list-item="{ item }">
      <div class="gl-flex gl-items-center">
        <gl-avatar
          :src="item.avatar_url"
          :entity-id="item.id"
          :entity-name="item.name"
          :shape="$options.AVATAR_SHAPE_OPTION_RECT"
          :size="32"
          class="gl-mr-3"
          aria-hidden="true"
        />
        <div class="gl-flex gl-flex-col">
          <span
            v-safe-html="highlightedItemName(item)"
            class="gl-whitespace-nowrap gl-font-bold"
            data-testid="item-title"
          ></span>
          <span class="gl-text-sm gl-text-subtle" data-testid="item-namespace">
            {{ truncatedNamespace(item) }}</span
          >
        </div>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
