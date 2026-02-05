<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { produce } from 'immer';
import { s__, n__ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { ROUTES } from '~/work_items/constants';
import getSubscribedSavedViewsQuery from '~/work_items/list/graphql/work_item_saved_views_namespace.query.graphql';
import workItemSavedViewDelete from '~/work_items/graphql/delete_saved_view.mutation.graphql';
import workItemSavedViewUnsubscribe from '~/work_items/list/graphql/unsubscribe_from_saved_view.mutation.graphql';
import WorkItemsCreateSavedViewDropdown from './work_items_create_saved_view_dropdown.vue';
import WorkItemsSavedViewSelector from './work_items_saved_view_selector.vue';

export default {
  name: 'WorkItemsSavedViewsSelectors',
  components: {
    WorkItemsCreateSavedViewDropdown,
    WorkItemsSavedViewSelector,
    GlDisclosureDropdown,
  },
  i18n: {
    defaultViewtitle: s__('WorkItem|All items'),
  },
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
  },
  watch: {
    savedViews() {
      this.$nextTick(this.detectViewsOverflow);
    },
  },
  mounted() {
    this.$nextTick(this.detectViewsOverflow);
    window.addEventListener('resize', this.detectViewsOverflow);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.detectViewsOverflow);
  },
  methods: {
    async detectViewsOverflow() {
      const { viewsWrapper, measureContainer } = this.$refs;

      if (!viewsWrapper || !measureContainer) return;

      // reset to full list so the wrapper we are measuring against can expand
      this.visibleViews = this.savedViews;
      this.overflowedViews = [];
      await this.$nextTick();

      const availableWidth = viewsWrapper.clientWidth;
      const items = measureContainer.children;

      let firstOverflowIndex = null;

      Array.from(items).some((item, index) => {
        const itemRight = item.offsetLeft + item.offsetWidth;

        // If item is overflowing the container, we are assigning the first overflow index
        if (itemRight > availableWidth) {
          firstOverflowIndex = Math.max(0, index - 2);
          return true;
        }
        return false;
      });

      if (firstOverflowIndex === null) {
        return;
      }

      // separating views into two arrays based on the first overflow index
      this.visibleViews = this.savedViews.slice(0, firstOverflowIndex);
      this.overflowedViews = this.savedViews.slice(firstOverflowIndex);
    },
    onOverflowViewClick(view) {
      const overflowIndex = this.overflowedViews.findIndex((item) => item.name === view.name);

      // swaps selected view with the last visible view to make it active
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
    updateCacheAfterRemoval(cache, viewId) {
      const query = {
        query: getSubscribedSavedViewsQuery,
        variables: {
          fullPath: this.fullPath,
          subscribedOnly: false,
        },
      };

      const sourceData = cache.readQuery(query);
      if (!sourceData) return;

      const newData = produce(sourceData, (draftState) => {
        const savedViews = draftState.namespace.savedViews.nodes;
        const index = savedViews.findIndex((v) => v.id === viewId);
        if (index !== -1) {
          savedViews.splice(index, 1);
        }
      });

      cache.writeQuery({ ...query, data: newData });
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
              errors: [],
              savedView: {
                __typename: 'WorkItemSavedViewType',
                id: view.id,
              },
            },
          },
          update: (cache) => this.updateCacheAfterRemoval(cache, view.id),
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
          variables: {
            input: {
              id: view.id,
            },
          },
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
          update: (cache) => this.updateCacheAfterRemoval(cache, view.id),
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
      class="gl-border-b gl-flex gl-w-full gl-min-w-0 gl-flex-nowrap sm:gl-border-none"
    >
      <button
        category="tertiary"
        class="default-selector gl-h-[50px] !gl-whitespace-nowrap gl-border-none gl-bg-transparent gl-px-4 hover:gl-bg-gray-50 focus:gl-bg-gray-50"
        :class="{ 'default-selector-active gl-font-bold': isDefaultButtonActive }"
        data-testid="saved-views-default-view-selector"
        @click="$emit('reset-to-default-view')"
      >
        {{ $options.i18n.defaultViewtitle }}
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
            @unsubscribe-saved-view="handleUnsubscribeFromView"
            @delete-saved-view="handleDeleteView"
          />
        </li>
      </ul>

      <ul
        ref="measureContainer"
        class="gl-pointer-events-none gl-invisible gl-absolute gl-mb-0 gl-flex gl-flex-nowrap gl-p-0"
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
            @unsubscribe-saved-view="handleUnsubscribeFromView"
            @delete-saved-view="handleDeleteView"
          />
        </li>
      </ul>

      <gl-disclosure-dropdown
        v-if="overflowedViews.length > 0"
        category="tertiary"
        :toggle-text="moreItemsText"
        no-caret
        left
        :items="overflowItems"
        class="gl-ml-4 gl-h-[32px] gl-self-center"
        data-testid="saved-views-more-toggle"
      />

      <work-items-create-saved-view-dropdown
        :full-path="fullPath"
        :sort-key="sortKey"
        class="gl-ml-2"
      />
    </div>

    <div
      class="gl-ml-auto gl-mt-3 gl-flex gl-items-center gl-justify-end gl-gap-3 sm:gl-ml-6 sm:gl-mt-0"
    >
      <slot name="header-area"></slot>
    </div>
  </div>
</template>
