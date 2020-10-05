<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon, GlButton, GlSearchBoxByType, GlLink } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';

import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';
import SmartVirtualList from '~/vue_shared/components/smart_virtual_list.vue';

import LabelItem from './label_item.vue';

import { LIST_BUFFER_SIZE } from './constants';

export default {
  LIST_BUFFER_SIZE,
  components: {
    GlLoadingIcon,
    GlButton,
    GlSearchBoxByType,
    GlLink,
    SmartVirtualList,
    LabelItem,
  },
  data() {
    return {
      searchKey: '',
      currentHighlightItem: -1,
    };
  },
  computed: {
    ...mapState([
      'allowLabelCreate',
      'allowMultiselect',
      'labelsManagePath',
      'labels',
      'labelsFetchInProgress',
      'labelsListTitle',
      'footerCreateLabelTitle',
      'footerManageLabelTitle',
    ]),
    ...mapGetters(['selectedLabelsList', 'isDropdownVariantSidebar', 'isDropdownVariantEmbedded']),
    visibleLabels() {
      if (this.searchKey) {
        return fuzzaldrinPlus.filter(this.labels, this.searchKey, {
          key: ['title'],
        });
      }
      return this.labels;
    },
    showListContainer() {
      if (this.isDropdownVariantSidebar) {
        return !this.labelsFetchInProgress;
      }

      return true;
    },
    showNoMatchingResultsMessage() {
      return !this.labelsFetchInProgress && !this.visibleLabels.length;
    },
  },
  watch: {
    searchKey(value) {
      // When there is search string present
      // and there are matching results,
      // highlight first item by default.
      if (value && this.visibleLabels.length) {
        this.currentHighlightItem = 0;
      }
    },
  },
  mounted() {
    this.fetchLabels();
  },
  methods: {
    ...mapActions([
      'toggleDropdownContents',
      'toggleDropdownContentsCreateView',
      'fetchLabels',
      'updateSelectedLabels',
      'toggleDropdownContents',
    ]),
    isLabelSelected(label) {
      return this.selectedLabelsList.includes(label.id);
    },
    /**
     * This method scrolls item from dropdown into
     * the view if it is off the viewable area of the
     * container.
     */
    scrollIntoViewIfNeeded() {
      const highlightedLabel = this.$refs.labelsListContainer.querySelector('.is-focused');

      if (highlightedLabel) {
        const rect = highlightedLabel.getBoundingClientRect();
        if (rect.bottom > this.$refs.labelsListContainer.clientHeight) {
          highlightedLabel.scrollIntoView(false);
        }
        if (rect.top < 0) {
          highlightedLabel.scrollIntoView();
        }
      }
    },
    /**
     * This method enables keyboard navigation support for
     * the dropdown.
     */
    handleKeyDown(e) {
      if (e.keyCode === UP_KEY_CODE && this.currentHighlightItem > 0) {
        this.currentHighlightItem -= 1;
      } else if (
        e.keyCode === DOWN_KEY_CODE &&
        this.currentHighlightItem < this.visibleLabels.length - 1
      ) {
        this.currentHighlightItem += 1;
      } else if (e.keyCode === ENTER_KEY_CODE && this.currentHighlightItem > -1) {
        this.updateSelectedLabels([this.visibleLabels[this.currentHighlightItem]]);
        this.searchKey = '';
      } else if (e.keyCode === ESC_KEY_CODE) {
        this.toggleDropdownContents();
      }

      if (e.keyCode !== ESC_KEY_CODE) {
        // Scroll the list only after highlighting
        // styles are rendered completely.
        this.$nextTick(() => {
          this.scrollIntoViewIfNeeded();
        });
      }
    },
    handleLabelClick(label) {
      this.updateSelectedLabels([label]);
      if (!this.allowMultiselect) this.toggleDropdownContents();
    },
  },
};
</script>

<template>
  <div class="labels-select-contents-list js-labels-list" @keydown="handleKeyDown">
    <gl-loading-icon
      v-if="labelsFetchInProgress"
      class="labels-fetch-loading position-absolute gl-display-flex gl-align-items-center w-100 h-100"
      size="md"
    />
    <div
      v-if="isDropdownVariantSidebar || isDropdownVariantEmbedded"
      class="dropdown-title gl-display-flex gl-align-items-center gl-pt-0 gl-pb-3!"
      data-testid="dropdown-title"
    >
      <span class="flex-grow-1">{{ labelsListTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        variant="link"
        size="small"
        class="dropdown-header-button gl-p-0!"
        icon="close"
        @click="toggleDropdownContents"
      />
    </div>
    <div class="dropdown-input" @click.stop="() => {}">
      <gl-search-box-by-type
        v-model="searchKey"
        :autofocus="true"
        data-qa-selector="dropdown_input_field"
      />
    </div>
    <div
      v-show="showListContainer"
      ref="labelsListContainer"
      class="dropdown-content"
      data-testid="dropdown-content"
    >
      <smart-virtual-list
        :length="visibleLabels.length"
        :remain="$options.LIST_BUFFER_SIZE"
        :size="$options.LIST_BUFFER_SIZE"
        wclass="list-unstyled mb-0"
        wtag="ul"
        class="h-100"
      >
        <li v-for="(label, index) in visibleLabels" :key="label.id" class="d-block text-left">
          <label-item
            :label="label"
            :is-label-set="label.set"
            :highlight="index === currentHighlightItem"
            @clickLabel="handleLabelClick(label)"
          />
        </li>
        <li v-show="showNoMatchingResultsMessage" class="gl-p-3 gl-text-center">
          {{ __('No matching results') }}
        </li>
      </smart-virtual-list>
    </div>
    <div
      v-if="isDropdownVariantSidebar || isDropdownVariantEmbedded"
      class="dropdown-footer"
      data-testid="dropdown-footer"
    >
      <ul class="list-unstyled">
        <li v-if="allowLabelCreate">
          <gl-link
            class="gl-display-flex w-100 flex-row text-break-word label-item"
            @click="toggleDropdownContentsCreateView"
          >
            {{ footerCreateLabelTitle }}
          </gl-link>
        </li>
        <li>
          <gl-link
            :href="labelsManagePath"
            class="gl-display-flex flex-row text-break-word label-item"
          >
            {{ footerManageLabelTitle }}
          </gl-link>
        </li>
      </ul>
    </div>
  </div>
</template>
