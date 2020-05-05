<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon, GlButton, GlIcon, GlSearchBoxByType, GlLink } from '@gitlab/ui';

import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';

export default {
  components: {
    GlLoadingIcon,
    GlButton,
    GlIcon,
    GlSearchBoxByType,
    GlLink,
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
    ...mapGetters(['selectedLabelsList', 'isDropdownVariantSidebar']),
    visibleLabels() {
      if (this.searchKey) {
        return this.labels.filter(label =>
          label.title.toLowerCase().includes(this.searchKey.toLowerCase()),
        );
      }
      return this.labels;
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
    getDropdownLabelBoxStyle(label) {
      return {
        backgroundColor: label.color,
      };
    },
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
      class="labels-fetch-loading position-absolute d-flex align-items-center w-100 h-100"
      size="md"
    />
    <div v-if="isDropdownVariantSidebar" class="dropdown-title d-flex align-items-center pt-0 pb-2">
      <span class="flex-grow-1">{{ labelsListTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        variant="link"
        size="small"
        class="dropdown-header-button p-0"
        icon="close"
        @click="toggleDropdownContents"
      />
    </div>
    <div class="dropdown-input">
      <gl-search-box-by-type v-model="searchKey" :autofocus="true" />
    </div>
    <div v-if="!labelsFetchInProgress" ref="labelsListContainer" class="dropdown-content">
      <ul class="list-unstyled mb-0">
        <li v-for="(label, index) in visibleLabels" :key="label.id" class="d-block text-left">
          <gl-link
            class="d-flex align-items-baseline text-break-word label-item"
            :class="{ 'is-focused': index === currentHighlightItem }"
            @click="handleLabelClick(label)"
          >
            <gl-icon v-show="label.set" name="mobile-issue-close" class="mr-2 align-self-center" />
            <span v-show="!label.set" class="mr-3 pr-2"></span>
            <span class="dropdown-label-box" :style="getDropdownLabelBoxStyle(label)"></span>
            <span>{{ label.title }}</span>
          </gl-link>
        </li>
        <li v-if="!visibleLabels.length" class="p-2 text-center">
          {{ __('No matching results') }}
        </li>
      </ul>
    </div>
    <div v-if="isDropdownVariantSidebar" class="dropdown-footer">
      <ul class="list-unstyled">
        <li v-if="allowLabelCreate">
          <gl-link
            class="d-flex w-100 flex-row text-break-word label-item"
            @click="toggleDropdownContentsCreateView"
            >{{ footerCreateLabelTitle }}</gl-link
          >
        </li>
        <li>
          <gl-link :href="labelsManagePath" class="d-flex flex-row text-break-word label-item">
            {{ footerManageLabelTitle }}
          </gl-link>
        </li>
      </ul>
    </div>
  </div>
</template>
