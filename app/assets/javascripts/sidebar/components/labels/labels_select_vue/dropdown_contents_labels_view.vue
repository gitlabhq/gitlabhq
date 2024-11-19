<script>
import {
  GlIntersectionObserver,
  GlLoadingIcon,
  GlButton,
  GlSearchBoxByType,
  GlLink,
} from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters, mapActions } from 'vuex';

import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';

import LabelItem from './label_item.vue';

// @deprecated This component should only be used when there is no GraphQL API.
// In most cases you should use
// `app/assets/javascripts/sidebar/components/labels/labels_select_widget/dropdown_contents_labels_view.vue` instead.
export default {
  components: {
    GlIntersectionObserver,
    GlLoadingIcon,
    GlButton,
    GlSearchBoxByType,
    GlLink,
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
    showDropdownFooter() {
      return (
        (this.isDropdownVariantSidebar || this.isDropdownVariantEmbedded) &&
        (this.allowLabelCreate || this.labelsManagePath)
      );
    },
    showNoMatchingResultsMessage() {
      return Boolean(this.searchKey) && this.visibleLabels.length === 0;
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
  methods: {
    ...mapActions([
      'toggleDropdownContents',
      'toggleDropdownContentsCreateView',
      'fetchLabels',
      'receiveLabelsSuccess',
      'updateSelectedLabels',
      'toggleDropdownContents',
    ]),
    /**
     * This method scrolls item from dropdown into
     * the view if it is off the viewable area of the
     * container.
     */
    scrollIntoViewIfNeeded() {
      const highlightedLabel = this.$refs.labelsListContainer.querySelector('.is-focused');

      if (highlightedLabel) {
        const container = this.$refs.labelsListContainer.getBoundingClientRect();
        const label = highlightedLabel.getBoundingClientRect();

        if (label.bottom > container.bottom) {
          this.$refs.labelsListContainer.scrollTop += label.bottom - container.bottom;
        } else if (label.top < container.top) {
          this.$refs.labelsListContainer.scrollTop -= container.top - label.top;
        }
      }
    },
    handleComponentAppear() {
      // We can avoid putting `catch` block here
      // as failure is handled within actions.js already.
      return this.fetchLabels().then(() => {
        this.$refs.searchInput.focusInput();
      });
    },
    /**
     * We want to remove loaded labels to ensure component
     * fetches fresh set of labels every time when shown.
     */
    handleComponentDisappear() {
      this.receiveLabelsSuccess([]);
    },
    handleCreateLabelClick() {
      this.receiveLabelsSuccess([]);
      this.toggleDropdownContentsCreateView();
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

        // Prevent parent form submission upon hitting enter.
        e.preventDefault();
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
  <gl-intersection-observer @appear="handleComponentAppear" @disappear="handleComponentDisappear">
    <div
      class="labels-select-contents-list js-labels-list"
      data-testid="labels-list"
      @keydown="handleKeyDown"
    >
      <div
        v-if="isDropdownVariantSidebar || isDropdownVariantEmbedded"
        class="dropdown-title gl-flex gl-items-center !gl-pb-3 gl-pt-0"
        data-testid="dropdown-title"
      >
        <span class="flex-grow-1">{{ labelsListTitle }}</span>
        <gl-button
          :aria-label="__('Close')"
          category="tertiary"
          size="small"
          class="dropdown-header-button !gl-p-0"
          icon="close"
          @click="toggleDropdownContents"
        />
      </div>
      <div class="dropdown-input" @click.stop="() => {}">
        <gl-search-box-by-type
          ref="searchInput"
          v-model="searchKey"
          :disabled="labelsFetchInProgress"
          data-testid="dropdown-input-field"
        />
      </div>
      <div ref="labelsListContainer" class="dropdown-content" data-testid="dropdown-content">
        <gl-loading-icon
          v-if="labelsFetchInProgress"
          class="labels-fetch-loading gl-h-full gl-w-full gl-items-center"
          size="lg"
        />
        <ul v-else class="list-unstyled gl-mb-0 gl-break-anywhere">
          <label-item
            v-for="(label, index) in visibleLabels"
            :key="label.id"
            :label="label"
            :is-label-set="label.set"
            :is-label-indeterminate="label.indeterminate"
            :highlight="index === currentHighlightItem"
            @clickLabel="handleLabelClick(label)"
          />
          <li
            v-show="showNoMatchingResultsMessage"
            class="gl-p-3 gl-text-center"
            data-testid="no-matching-results"
          >
            {{ __('No matching results') }}
          </li>
        </ul>
      </div>
      <div v-if="showDropdownFooter" class="dropdown-footer" data-testid="dropdown-footer">
        <ul class="list-unstyled">
          <li v-if="allowLabelCreate">
            <gl-link
              class="flex-row label-item gl-flex gl-w-full gl-break-all"
              data-testid="create-label-link"
              @click="handleCreateLabelClick"
            >
              {{ footerCreateLabelTitle }}
            </gl-link>
          </li>
          <li v-if="labelsManagePath">
            <gl-link :href="labelsManagePath" class="flex-row label-item gl-flex gl-break-all">
              {{ footerManageLabelTitle }}
            </gl-link>
          </li>
        </ul>
      </div>
    </div>
  </gl-intersection-observer>
</template>
