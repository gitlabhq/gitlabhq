<script>
import {
  GlModal,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlSearchBoxByType,
  GlSkeletonLoader,
  GlAlert,
  GlEmptyState,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { __, s__, sprintf } from '~/locale';
import {
  fetchRefs,
  fetchMostRecentlyUpdated,
  createRefId,
} from '../security_attributes/api/refs_api';
import RefTrackingMetadata from './ref_tracking_metadata.vue';
import RefTrackingSelectionSummary from './ref_tracking_selection_summary.vue';

const SEARCH_DEBOUNCE_DELAY = 300;
const SEARCH_TERM_MIN_LENGTH = 3;
const MAX_DISPLAYED_REFS = 6;

export default {
  name: 'RefTrackingSelection',
  components: {
    GlModal,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlSearchBoxByType,
    GlSkeletonLoader,
    GlAlert,
    GlEmptyState,
    RefTrackingMetadata,
    RefTrackingSelectionSummary,
  },
  inject: ['projectFullPath'],
  props: {
    trackedRefs: {
      type: Array,
      required: false,
      default: () => [],
    },
    maxTrackedRefs: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedRefs: [],
      mostRecentlyUpdatedRefs: [],
      searchResults: [],
      errorMessage: '',
      isSearching: false,
      isLoading: false,
      searchAbortController: null,
    };
  },
  computed: {
    selectedRefIds() {
      return this.selectedRefs.map((ref) => ref.id);
    },
    searchTermHasMinLength() {
      return this.searchTerm.length >= SEARCH_TERM_MIN_LENGTH;
    },
    normalizedTrackedRefIds() {
      // `trackedRefs` is coming via GraphQL, so we need to extract the same ids as the REST results
      return this.trackedRefs.map((ref) => createRefId(ref.refType, ref.name));
    },
    displayedRefs() {
      const refsList = this.searchTermHasMinLength
        ? this.searchResults
        : this.mostRecentlyUpdatedRefs;

      return (
        refsList
          .filter((ref) => !this.normalizedTrackedRefIds.includes(ref.id))
          // Because we over-fetch (to balance the filtered out tracked refs) we need to make sure that we don't render too many
          .slice(0, MAX_DISPLAYED_REFS)
      );
    },
    showLoadingState() {
      return this.isLoading || this.isSearching;
    },
    showEmptyState() {
      return !this.showLoadingState && this.displayedRefs.length === 0;
    },
    searchResultsHeading() {
      return sprintf(s__('SecurityTrackedRefs|Search results for "%{searchTerm}"'), {
        searchTerm: this.searchTerm,
      });
    },
    emptyStateContent() {
      const title = this.searchTermHasMinLength
        ? __('No results found')
        : s__('SecurityTrackedRefs|No refs available');
      const description = this.searchTermHasMinLength
        ? __('Edit your search and try again.')
        : s__('SecurityTrackedRefs|There are no refs available to track.');

      return { title, description };
    },
    modalTitle() {
      return s__('SecurityTrackedRefs|Track ref(s)');
    },
    actionPrimaryProps() {
      return {
        text: s__('SecurityTrackedRefs|Track ref(s)'),
        attributes: {
          variant: 'confirm',
          disabled: !this.selectedRefIds.length,
        },
      };
    },
    actionCancelProps() {
      return {
        text: __('Cancel'),
      };
    },
    availableSpots() {
      return Math.max(
        0,
        this.maxTrackedRefs - (this.trackedRefs.length + this.selectedRefs.length),
      );
    },
  },
  watch: {
    searchTerm: {
      handler(value) {
        if (this.searchTermHasMinLength) {
          this.isSearching = true;
          this.debouncedSearch(value);
        } else {
          this.searchAbortController?.abort();
          this.debouncedSearch?.cancel();
          this.searchResults = [];
          this.isSearching = false;
        }
      },
    },
  },
  created() {
    this.debouncedSearch = debounce(this.search, SEARCH_DEBOUNCE_DELAY);
    this.fetchMostRecentlyUpdatedRefs();
  },
  beforeDestroy() {
    this.debouncedSearch?.cancel();
    this.searchAbortController?.abort();
  },
  methods: {
    async fetchMostRecentlyUpdatedRefs() {
      this.isLoading = true;

      try {
        this.mostRecentlyUpdatedRefs = await fetchMostRecentlyUpdated(this.projectFullPath, {
          // Fetch more than needed to ensure we have enough results after filtering out tracked refs
          limit: MAX_DISPLAYED_REFS + this.trackedRefs.length,
        });
      } catch {
        this.errorMessage = s__(
          'SecurityTrackedRefs|Could not fetch available refs. Please try again later.',
        );
      } finally {
        this.isLoading = false;
      }
    },
    async search(term) {
      this.searchAbortController?.abort();

      this.searchAbortController = new AbortController();
      this.errorMessage = '';

      try {
        this.searchResults = await fetchRefs(
          this.projectFullPath,
          {
            search: term,
            limit: MAX_DISPLAYED_REFS,
          },
          this.searchAbortController.signal,
        );
      } catch (error) {
        const requestCancelled = axios.isCancel(error);

        if (!requestCancelled) {
          this.errorMessage = s__(
            'SecurityTrackedRefs|Could not search refs. Please try again later.',
          );
        }
      } finally {
        this.searchAbortController = null;
        this.isSearching = false;
      }
    },
    isRefSelected(ref) {
      return this.selectedRefIds.includes(ref.id);
    },
    canRefBeToggled(ref) {
      return this.availableSpots > 0 || this.isRefSelected(ref);
    },
    toggleRef(ref) {
      if (!this.canRefBeToggled(ref)) {
        return;
      }

      if (this.isRefSelected(ref)) {
        this.selectedRefs = this.selectedRefs.filter((selectedRef) => selectedRef.id !== ref.id);
      } else {
        this.selectedRefs.push(ref);
      }
    },
    handlePrimary() {
      this.$emit('select', this.selectedRefs);
    },
    handleHidden() {
      this.$emit('cancel');
    },
  },
};
</script>

<template>
  <gl-modal
    visible
    :title="modalTitle"
    hide-header
    hide-header-close
    scrollable
    :action-primary="actionPrimaryProps"
    :action-cancel="actionCancelProps"
    modal-id="track-ref-selection-modal"
    modal-class="gl-pt-12 gl-px-2 sm:gl-pt-20 sm:gl-px-4 [&_.modal-dialog]:!gl-items-start"
    size="lg"
    :centered="false"
    @primary="handlePrimary"
    @hidden="handleHidden"
  >
    <gl-search-box-by-type
      v-model="searchTerm"
      autocomplete="off"
      :placeholder="
        s__('SecurityTrackedRefs|Search branches and tags (enter at least 3 characters)')
      "
      class="gl-mb-4 gl-mt-3"
      data-testid="ref-search-input"
    />

    <ref-tracking-selection-summary
      :selected-refs="selectedRefs"
      :available-spots="availableSpots"
      @remove="toggleRef"
    />

    <gl-alert
      v-if="errorMessage"
      variant="danger"
      class="gl-mb-4"
      :dismissible="false"
      data-testid="fetch-error-alert"
    >
      {{ errorMessage }}
    </gl-alert>

    <div v-if="showLoadingState" class="gl-py-4" data-testid="loading-skeleton">
      <gl-skeleton-loader v-for="i in 5" :key="i" :width="600" :height="60">
        <rect width="150" height="12" x="0" y="0" rx="4" />
        <rect width="80" height="10" x="0" y="20" rx="4" />
        <rect width="450" height="10" x="0" y="38" rx="4" />
      </gl-skeleton-loader>
    </div>

    <template v-if="!showLoadingState && !errorMessage">
      <h3
        v-if="!showEmptyState"
        class="gl-my-4 gl-text-base gl-font-semibold"
        data-testid="list-header"
      >
        {{
          searchTermHasMinLength
            ? searchResultsHeading
            : s__('SecurityTrackedRefs|Most recently updated')
        }}
      </h3>
      <gl-empty-state
        v-if="showEmptyState"
        :title="emptyStateContent.title"
        :description="emptyStateContent.description"
        svg-path=""
        :svg-height="150"
        data-testid="empty-state"
      />
      <gl-form-checkbox-group v-else :checked="selectedRefIds">
        <ul class="gl-m-0 gl-list-none gl-p-0">
          <li
            v-for="ref in displayedRefs"
            :key="ref.id"
            class="gl-border-b gl-cursor-pointer gl-p-4 last:gl-border-b-0 hover:gl-bg-gray-50"
            :class="{
              '!gl-cursor-not-allowed': !canRefBeToggled(ref),
              'hover:gl-bg-inherit': !canRefBeToggled(ref),
            }"
            :data-testid="`ref-list-item-${ref.id}`"
            @click="toggleRef(ref)"
          >
            <!-- We use the `@click` handler within the `li` so the whole item is clickable, not just the checkbox, therefor we need to disable pointer events on the checkbox -->
            <gl-form-checkbox
              :value="ref.id"
              class="gl-pointer-events-none gl-grid gl-items-start"
              :disabled="!canRefBeToggled(ref)"
            >
              <div class="gl-ml-2">
                <ref-tracking-metadata :tracked-ref="ref" :disable-commit-link="true" />
              </div>
            </gl-form-checkbox>
          </li>
        </ul>
      </gl-form-checkbox-group>
    </template>
  </gl-modal>
</template>
