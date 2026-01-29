<script>
import {
  GlModal,
  GlSearchBoxByType,
  GlButton,
  GlIcon,
  GlTooltipDirective,
  GlLoadingIcon,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getNamespaceSavedViewsQuery from '../graphql/work_item_saved_views_namespace.query.graphql';

export default {
  name: 'WorkItemsExistingSavedViewsModal',
  components: {
    GlModal,
    GlSearchBoxByType,
    GlButton,
    GlIcon,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    title: s__('WorkItem|Views'),
    searchPlaceholder: s__('WorkItem|Search by view name or description'),
    emptyViews: s__('WorkItem|No views currently exist'),
    emptyViewsDescription: s__(
      'WorkItem|Views created by you or shared by others will show up here.',
    ),
    notFound: s__('WorkItem|No results found'),
    notFoundDescription: s__('WorkItem|Edit your search and try again.'),
    privateTooltip: s__('WorkItem|Private: only you can see and edit this view.'),
  },
  model: {
    prop: 'show',
    event: 'hide',
  },
  props: {
    show: {
      type: Boolean,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
  },
  emits: ['hide', 'show-new-view-modal'],
  data() {
    return {
      searchInput: '',
      savedViews: [],
    };
  },
  apollo: {
    savedViews: {
      query: getNamespaceSavedViewsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          subscribedOnly: false,
        };
      },
      update(data) {
        return data.namespace?.savedViews.nodes ?? [];
      },
      error(e) {
        Sentry.captureException(e);
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.savedViews.loading;
    },
    hasSavedViews() {
      return this.savedViews.length > 0;
    },
    hasSearchInput() {
      return this.searchInput.trim().length > 0;
    },
    filteredViews() {
      if (!this.hasSearchInput) {
        return this.savedViews;
      }

      return this.savedViews.filter(({ title, description }) =>
        [title, description].some((field) =>
          field?.toLowerCase().includes(this.searchInput.trim().toLowerCase()),
        ),
      );
    },
  },
  methods: {
    focusSearchInput() {
      this.$refs.savedViewSearch?.$el.focus();
    },
    hideModal() {
      this.$emit('hide', false);
      this.searchInput = '';
    },
    redirectToNewViewModal() {
      this.$emit('hide', false);
      this.$emit('show-new-view-modal');
    },
  },
};
</script>
<template>
  <gl-modal
    modal-id="add-existing-view-modal"
    modal-class="add-existing-view-modal"
    :aria-label="$options.i18n.title"
    :title="$options.i18n.title"
    :visible="show"
    body-class="!gl-pb-0"
    size="sm"
    hide-footer
    @shown="focusSearchInput"
    @hide="hideModal"
  >
    <gl-search-box-by-type
      ref="savedViewSearch"
      v-model="searchInput"
      :disabled="!hasSavedViews"
      :placeholder="$options.i18n.searchPlaceholder"
    />
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />

    <template v-if="!hasSavedViews">
      <div class="gl-mt-4 gl-pb-7 gl-text-center">
        <h3 class="gl-mb-2 gl-text-lg gl-text-default">
          {{ $options.i18n.emptyViews }}
        </h3>
        <span>{{ $options.i18n.emptyViewsDescription }}</span>
        <gl-button
          variant="confirm"
          class="gl-mt-5"
          data-testid="new-view-button"
          @click="redirectToNewViewModal"
        >
          {{ s__('WorkItem|New View') }}
        </gl-button>
      </div>
    </template>

    <template v-else-if="hasSearchInput && !filteredViews.length > 0">
      <div class="gl-mt-6 gl-pb-7 gl-text-center">
        <h3 class="gl-mb-2 gl-text-lg gl-text-default">
          {{ $options.i18n.notFound }}
        </h3>
        <span>{{ $options.i18n.notFoundDescription }}</span>
      </div>
    </template>

    <template v-else>
      <ul class="gl-mb-3 gl-mt-[6px] gl-max-h-[25rem] gl-overflow-scroll gl-p-0 gl-px-1">
        <li v-for="view in filteredViews" :key="view.id" class="gl-my-1">
          <button
            class="saved-view-item gl-flex gl-w-full gl-cursor-pointer gl-rounded-base gl-border-none gl-px-4 gl-py-3 hover:gl-bg-gray-50 focus:gl-bg-gray-50"
            data-testid="saved-view-item"
            @click="hideModal"
          >
            <gl-icon name="list-bulleted" class="gl-mr-3 gl-shrink-0" variant="subtle" />
            <span class="gl-text-start">
              <h5 class="gl-m-0">
                {{ view.name }}
                <gl-icon
                  v-if="view.isPrivate"
                  v-gl-tooltip
                  :title="$options.i18n.privateTooltip"
                  name="lock"
                  class="gl-mr-3 gl-shrink-0 gl-cursor-pointer"
                  variant="subtle"
                  data-testid="private-view-icon"
                />
              </h5>
              <span class="gl-text-sm gl-text-subtle">
                {{ view.description }}
              </span>
            </span>
            <template v-if="view.subscribed">
              <div
                class="added-saved-view gl-ml-auto gl-flex gl-items-center gl-gap-1 gl-text-success"
              >
                <gl-icon
                  name="check"
                  class="gl-shrink-0 gl-text-success"
                  data-testid="subscribed-view-icon"
                />
                <span class="gl-text-sm">
                  {{ s__('WorkItem|Added') }}
                </span>
              </div>
              <gl-icon
                name="arrow-right"
                class="added-saved-view-arrow gl-ml-auto gl-hidden gl-shrink-0"
              />
            </template>
            <template v-else>
              <gl-icon
                name="plus"
                class="add-saved-view gl-ml-auto gl-hidden gl-shrink-0 gl-items-center"
              />
            </template>
          </button>
        </li>
      </ul>
    </template>
  </gl-modal>
</template>
