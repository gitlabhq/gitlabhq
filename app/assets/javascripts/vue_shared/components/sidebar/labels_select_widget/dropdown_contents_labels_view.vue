<script>
import { GlLoadingIcon, GlSearchBoxByType, GlLink } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { debounce } from 'lodash';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { UP_KEY_CODE, DOWN_KEY_CODE, ENTER_KEY_CODE, ESC_KEY_CODE } from '~/lib/utils/keycodes';
import { __ } from '~/locale';
import { DropdownVariant } from './constants';
import projectLabelsQuery from './graphql/project_labels.query.graphql';
import LabelItem from './label_item.vue';

export default {
  components: {
    GlLoadingIcon,
    GlSearchBoxByType,
    GlLink,
    LabelItem,
  },
  inject: ['projectPath', 'allowLabelCreate', 'labelsManagePath', 'variant'],
  props: {
    selectedLabels: {
      type: Array,
      required: true,
    },
    allowMultiselect: {
      type: Boolean,
      required: true,
    },
    labelsListTitle: {
      type: String,
      required: true,
    },
    footerCreateLabelTitle: {
      type: String,
      required: true,
    },
    footerManageLabelTitle: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchKey: '',
      labels: [],
      currentHighlightItem: -1,
      localSelectedLabels: [...this.selectedLabels],
    };
  },
  apollo: {
    labels: {
      query: projectLabelsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          searchTerm: this.searchKey,
        };
      },
      skip() {
        return this.searchKey.length === 1;
      },
      update: (data) => data.workspace?.labels?.nodes || [],
      async result() {
        if (this.$refs.searchInput) {
          await this.$nextTick();
          this.$refs.searchInput.focusInput();
        }
      },
      error() {
        createFlash({ message: __('Error fetching labels.') });
      },
    },
  },
  computed: {
    isDropdownVariantSidebar() {
      return this.variant === DropdownVariant.Sidebar;
    },
    isDropdownVariantEmbedded() {
      return this.variant === DropdownVariant.Embedded;
    },
    labelsFetchInProgress() {
      return this.$apollo.queries.labels.loading;
    },
    localSelectedLabelsIds() {
      return this.localSelectedLabels.map((label) => label.id);
    },
    visibleLabels() {
      if (this.searchKey) {
        return fuzzaldrinPlus.filter(this.labels, this.searchKey, {
          key: ['title'],
        });
      }
      return this.labels;
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
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  beforeDestroy() {
    this.$emit('closeDropdown', this.localSelectedLabels);
    this.debouncedSearchKeyUpdate.cancel();
  },
  methods: {
    isLabelSelected(label) {
      return this.localSelectedLabelsIds.includes(getIdFromGraphQLId(label.id));
    },
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
    updateSelectedLabels(label) {
      if (this.isLabelSelected(label)) {
        this.localSelectedLabels = this.localSelectedLabels.filter(
          ({ id }) => id !== getIdFromGraphQLId(label.id),
        );
      } else {
        this.localSelectedLabels.push({
          ...label,
          id: getIdFromGraphQLId(label.id),
        });
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
        this.updateSelectedLabels(this.visibleLabels[this.currentHighlightItem]);
        this.searchKey = '';
      } else if (e.keyCode === ESC_KEY_CODE) {
        this.$emit('closeDropdown', this.localSelectedLabels);
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
      this.updateSelectedLabels(label);
      if (!this.allowMultiselect) {
        this.$emit('closeDropdown', this.localSelectedLabels);
      }
    },
    setSearchKey(value) {
      this.searchKey = value;
    },
  },
};
</script>

<template>
  <div
    class="labels-select-contents-list js-labels-list"
    data-testid="dropdown-wrapper"
    @keydown="handleKeyDown"
  >
    <div class="dropdown-input" @click.stop="() => {}">
      <gl-search-box-by-type
        ref="searchInput"
        :value="searchKey"
        :disabled="labelsFetchInProgress"
        data-qa-selector="dropdown_input_field"
        data-testid="dropdown-input-field"
        @input="debouncedSearchKeyUpdate"
      />
    </div>
    <div ref="labelsListContainer" class="dropdown-content" data-testid="dropdown-content">
      <gl-loading-icon
        v-if="labelsFetchInProgress"
        class="labels-fetch-loading gl-align-items-center gl-w-full gl-h-full"
        size="md"
      />
      <ul v-else class="list-unstyled gl-mb-0 gl-word-break-word" data-testid="labels-list">
        <label-item
          v-for="(label, index) in visibleLabels"
          :key="label.id"
          :label="label"
          :is-label-set="isLabelSelected(label)"
          :highlight="index === currentHighlightItem"
          @clickLabel="handleLabelClick(label)"
        />
        <li
          v-show="showNoMatchingResultsMessage"
          class="gl-p-3 gl-text-center"
          data-testid="no-results"
        >
          {{ __('No matching results') }}
        </li>
      </ul>
    </div>
    <div
      v-if="isDropdownVariantSidebar || isDropdownVariantEmbedded"
      class="dropdown-footer"
      data-testid="dropdown-footer"
    >
      <ul class="list-unstyled">
        <li v-if="allowLabelCreate">
          <gl-link
            class="gl-display-flex gl-flex-direction-row gl-w-full gl-overflow-break-word label-item"
            data-testid="create-label-button"
            @click="$emit('toggleDropdownContentsCreateView')"
          >
            {{ footerCreateLabelTitle }}
          </gl-link>
        </li>
        <li>
          <gl-link
            :href="labelsManagePath"
            class="gl-display-flex gl-flex-direction-row gl-w-full gl-overflow-break-word label-item"
          >
            {{ footerManageLabelTitle }}
          </gl-link>
        </li>
      </ul>
    </div>
  </div>
</template>
