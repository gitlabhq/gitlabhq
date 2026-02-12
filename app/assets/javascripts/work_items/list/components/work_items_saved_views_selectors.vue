<script>
import { GlDisclosureDropdown, GlResizeObserverDirective } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__, n__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ROUTES } from '~/work_items/constants';
import { updateCacheAfterViewRemoval } from 'ee_else_ce/work_items/list/utils';
import workItemSavedViewDelete from '~/work_items/graphql/delete_saved_view.mutation.graphql';
import workItemSavedViewUnsubscribe from '~/work_items/list/graphql/unsubscribe_from_saved_view.mutation.graphql';
import WorkItemsCreateSavedViewDropdown from './work_items_create_saved_view_dropdown.vue';
import WorkItemsSavedViewSelector from './work_items_saved_view_selector.vue';

// Fallback widths in case refs aren't available yet
const DEFAULT_BUTTON_WIDTH = 100;

export default {
  name: 'WorkItemsSavedViewsSelectors',
  components: {
    WorkItemsCreateSavedViewDropdown,
    WorkItemsSavedViewSelector,
    GlDisclosureDropdown,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  i18n: {
    defaultViewTitle: s__('WorkItem|All items'),
  },
  inject: ['subscribedSavedViewLimit'],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    sortKey: {
      type: String,
      required: true,
    },
    savedViews: {
      type: Array,
      required: true,
    },
    filters: {
      type: Object,
      required: false,
      default: () => {},
    },
    displaySettings: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  emits: ['reset-to-default-view', 'error'],
  data() {
    return {
      visibleViews: [],
      overflowedViews: [],
    };
  },
  computed: {
    overflowItems() {
      return this.overflowedViews.map((view) => ({
        text: view.name,
        action: () => this.onOverflowViewClick(view),
      }));
    },
    moreItemsText() {
      return n__('WorkItem|%d more...', 'WorkItem|%d more...', this.overflowedViews.length);
    },
    isDefaultButtonActive() {
      return !window.location.pathname.includes('views');
    },
    isSubscriptionLimitReached() {
      return (
        this.subscribedSavedViewLimit && this.savedViews.length >= this.subscribedSavedViewLimit
      );
    },
    activeViewId() {
      return this.$route.params.view_id;
    },
  },
  watch: {
    savedViews() {
      this.$nextTick(this.detectViewsOverflow);
    },
    activeViewId() {
      this.$nextTick(this.detectViewsOverflow);
    },
  },
  created() {
    this.debouncedDetectOverflow = debounce(this.detectViewsOverflow, 100);
  },
  mounted() {
    this.$nextTick(this.detectViewsOverflow);
  },
  beforeDestroy() {
    this.debouncedDetectOverflow.cancel();
  },
  methods: {
    handleResize() {
      this.debouncedDetectOverflow();
    },
    /**
     * Calculates which views fit in the available space and which overflow.
     * Ensures the currently active view always remains visible by swapping
     * it with the last visible item if it would otherwise be in overflow.
     */
    async detectViewsOverflow() {
      const { viewsWrapper, measureContainer, defaultButton, addViewDropdown, overflowDropdown } =
        this.$refs;

      if (!viewsWrapper || !measureContainer) return;

      // Reset to full list so we can measure all items
      this.visibleViews = this.savedViews;
      this.overflowedViews = [];
      await this.$nextTick();

      // Use measured widths from refs, with fallbacks
      const defaultBtnWidth = defaultButton?.offsetWidth || DEFAULT_BUTTON_WIDTH;
      const addViewWidth = addViewDropdown?.$el?.offsetWidth || DEFAULT_BUTTON_WIDTH;
      const overflowWidth = overflowDropdown?.$el?.offsetWidth || DEFAULT_BUTTON_WIDTH;

      const availableWidth = viewsWrapper.clientWidth - defaultBtnWidth - addViewWidth;
      const items = Array.from(measureContainer.children);

      // Find the currently active view index
      const activeViewIndex = this.activeViewId
        ? this.savedViews.findIndex(
            (view) => getIdFromGraphQLId(view.id).toString() === this.activeViewId,
          )
        : -1;

      let totalWidth = 0;
      let firstOverflowIndex = null;

      items.some((item, index) => {
        const itemWidth = item.offsetWidth;
        const isLastItem = index === items.length - 1;
        const widthNeededForOverflow = isLastItem ? 0 : overflowWidth;

        if (totalWidth + itemWidth + widthNeededForOverflow > availableWidth) {
          // Push previous item to overflow to make room for current item
          firstOverflowIndex = Math.max(0, index - 1);
          return true;
        }

        totalWidth += itemWidth;
        return false;
      });

      if (firstOverflowIndex === null) return;

      const visible = this.savedViews.slice(0, firstOverflowIndex);
      let overflowed = this.savedViews.slice(firstOverflowIndex);

      // Ensure active view stays visible by swapping with last visible item
      if (activeViewIndex >= firstOverflowIndex && activeViewIndex !== -1) {
        const activeView = this.savedViews[activeViewIndex];
        overflowed = overflowed.filter((v) => v.id !== activeView.id);

        if (visible.length > 0) {
          const lastVisible = visible.pop();
          overflowed.unshift(lastVisible);
        }

        visible.push(activeView);
      }

      this.visibleViews = visible;
      this.overflowedViews = overflowed;
    },
    onOverflowViewClick(view) {
      const overflowIndex = this.overflowedViews.findIndex((item) => item.name === view.name);

      const [selectedOverflowView] = this.overflowedViews.splice(overflowIndex, 1);
      const removedVisibleView = this.visibleViews.pop();

      this.visibleViews.push(selectedOverflowView);
      this.overflowedViews.unshift(removedVisibleView);

      const id = getIdFromGraphQLId(view.id).toString();
      this.$router.push({ name: ROUTES.savedView, params: { view_id: id }, query: undefined });
    },
    getNextNearestView(viewIndex) {
      if (this.savedViews.length <= 1) return null;

      return viewIndex < this.savedViews.length - 1
        ? this.savedViews[viewIndex + 1]
        : this.savedViews[viewIndex - 1];
    },
    async navigateAfterViewRemoval(nextNearestView) {
      await this.detectViewsOverflow();

      if (nextNearestView) {
        const isInOverflow = this.overflowedViews.some((v) => v.id === nextNearestView.id);

        if (isInOverflow) {
          this.overflowedViews = this.overflowedViews.filter((v) => v.id !== nextNearestView.id);
          this.visibleViews = [...this.visibleViews, nextNearestView];
        }

        this.$router.push({
          name: ROUTES.savedView,
          params: { view_id: getIdFromGraphQLId(nextNearestView.id).toString() },
        });
      } else {
        this.$emit('reset-to-default-view');
      }
    },
    async handleUnsubscribeFromView(view) {
      if (!view) return;

      const viewIndex = this.savedViews.findIndex((v) => v.id === view.id);
      const nextNearestView = this.getNextNearestView(viewIndex);

      try {
        await this.$apollo.mutate({
          mutation: workItemSavedViewUnsubscribe,
          variables: {
            input: { id: view.id },
          },
          optimisticResponse: {
            workItemSavedViewUnsubscribe: {
              __typename: 'WorkItemSavedViewUnsubscribePayload',
              savedView: {
                __typename: 'WorkItemSavedViewType',
                id: view.id,
              },
            },
          },
          update: (cache) =>
            updateCacheAfterViewRemoval({
              cache,
              view,
              action: 'unsubscribe',
              fullPath: this.fullPath,
            }),
        });

        await this.navigateAfterViewRemoval(nextNearestView);
        this.$toast.show(s__('WorkItem|View removed from your list'));
      } catch (e) {
        this.$emit(
          'error',
          e,
          s__('WorkItem|An error occurred while removing the view. Please try again.'),
        );
      }
    },
    async handleDeleteView(view) {
      if (!view) return;

      const viewIndex = this.savedViews.findIndex((v) => v.id === view.id);
      const nextNearestView = this.getNextNearestView(viewIndex);

      try {
        await this.$apollo.mutate({
          mutation: workItemSavedViewDelete,
          variables: { input: { id: view.id } },
          optimisticResponse: {
            workItemSavedViewDelete: {
              __typename: 'WorkItemSavedViewDeletePayload',
              errors: [],
              savedView: {
                __typename: 'WorkItemSavedViewType',
                id: view.id,
              },
            },
          },
          update: (cache) =>
            updateCacheAfterViewRemoval({
              cache,
              view,
              action: 'delete',
              fullPath: this.fullPath,
            }),
        });

        await this.navigateAfterViewRemoval(nextNearestView);
        this.$toast.show(s__('WorkItem|View has been deleted'));
      } catch (e) {
        this.$emit(
          'error',
          e,
          s__('WorkItem|An error occurred while deleting the view. Please try again.'),
        );
      }
    },
  },
};
</script>

<template>
  <div
    class="saved-views-selectors gl-border-b gl-mb-3 gl-flex gl-flex-row gl-flex-wrap gl-justify-between gl-border-none sm:gl-border-b sm:gl-flex-nowrap"
  >
    <div
      ref="viewsWrapper"
      v-gl-resize-observer="handleResize"
      class="gl-border-b gl-flex gl-w-full gl-min-w-0 gl-flex-nowrap sm:gl-border-none"
    >
      <button
        ref="defaultButton"
        category="tertiary"
        class="default-selector gl-h-[50px] !gl-whitespace-nowrap gl-border-none gl-bg-transparent gl-px-4 hover:gl-bg-gray-50 focus:gl-bg-gray-50"
        :class="{ 'default-selector-active gl-font-bold': isDefaultButtonActive }"
        data-testid="saved-views-default-view-selector"
        @click="$emit('reset-to-default-view')"
      >
        {{ $options.i18n.defaultViewTitle }}
      </button>

      <ul ref="viewsContainer" class="gl-mb-0 gl-flex gl-flex-nowrap gl-overflow-hidden gl-p-0">
        <li
          v-for="view in visibleViews"
          :key="view.id"
          class="gl-flex gl-shrink-0 gl-whitespace-nowrap"
          data-testid="visible-view-selector"
        >
          <work-items-saved-view-selector
            :saved-view="view"
            :full-path="fullPath"
            :sort-key="sortKey"
            :filters="filters"
            :display-settings="displaySettings"
            @unsubscribe-saved-view="handleUnsubscribeFromView"
            @delete-saved-view="handleDeleteView"
          />
        </li>
      </ul>

      <!-- Hidden container for measuring all view widths -->
      <ul
        ref="measureContainer"
        class="gl-pointer-events-none gl-invisible gl-absolute gl-mb-0 gl-flex gl-flex-nowrap gl-p-0"
        aria-hidden="true"
      >
        <li
          v-for="view in savedViews"
          :key="view.id"
          class="gl-flex gl-shrink-0 gl-whitespace-nowrap"
        >
          <work-items-saved-view-selector
            :saved-view="view"
            :full-path="fullPath"
            :sort-key="sortKey"
            :filters="filters"
            :display-settings="displaySettings"
            @unsubscribe-saved-view="handleUnsubscribeFromView"
            @delete-saved-view="handleDeleteView"
          />
        </li>
      </ul>

      <gl-disclosure-dropdown
        v-if="overflowedViews.length > 0"
        ref="overflowDropdown"
        category="tertiary"
        :toggle-text="moreItemsText"
        no-caret
        left
        :items="overflowItems"
        class="gl-ml-4 gl-h-[32px] gl-self-center"
        data-testid="saved-views-more-toggle"
      />

      <work-items-create-saved-view-dropdown
        ref="addViewDropdown"
        :full-path="fullPath"
        :sort-key="sortKey"
        :filters="filters"
        :display-settings="displaySettings"
        :show-subscription-limit-warning="isSubscriptionLimitReached"
        class="gl-ml-2"
      />
    </div>

    <div
      class="gl-ml-auto gl-mt-3 gl-flex gl-items-center gl-justify-end gl-gap-3 sm:gl-ml-3 sm:gl-mt-0"
    >
      <slot name="header-area"></slot>
    </div>
  </div>
</template>
