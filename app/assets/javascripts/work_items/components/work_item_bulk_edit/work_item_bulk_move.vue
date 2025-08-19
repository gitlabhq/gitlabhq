<script>
import { GlCollapsibleListbox, GlFormGroup, GlButton } from '@gitlab/ui';
import { debounce, unionBy } from 'lodash';
import { s__, n__, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import namespaceProjectsQuery from '../../graphql/namespace_projects_for_links_widget.query.graphql';
import workItemBulkMoveMutation from '../../graphql/list/work_item_bulk_move.mutation.graphql';

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlFormGroup,
  },
  props: {
    checkedItems: {
      type: Array,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      searchStarted: false,
      selectedId: undefined,
      searchTerm: '',
      destinationNamespaces: [],
      isMoving: false,
      destinationNamespacesCache: [],
    };
  },
  apollo: {
    destinationNamespaces: {
      query: namespaceProjectsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          projectSearch: this.searchTerm,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.namespace?.projects?.nodes || [];
      },
      error(error) {
        createAlert({
          message: s__('WorkItem|Unable to fetch destination projects.'),
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    selectedNamespace() {
      return this.destinationNamespacesCache.find((namespace) => namespace.id === this.selectedId);
    },
    toggleText() {
      if (this.selectedNamespace) {
        return this.selectedNamespace.name;
      }
      return s__('WorkItem|Select destination');
    },
    listboxItems() {
      return this.destinationNamespaces?.map(({ id, name }) => ({ text: name, value: id })) || [];
    },
    isLoading() {
      return this.$apollo.queries.destinationNamespaces.loading;
    },
    buttonText() {
      if (this.hasNoItems) {
        return s__('WorkItem|No items selected');
      }
      if (this.selectedId === undefined) {
        return s__('WorkItem|No destination selected');
      }
      return n__('WorkItem|Move item', 'WorkItem|Move %d items', this.checkedItems.length);
    },
    hasNoItems() {
      return this.checkedItems.length === 0;
    },
    shouldDisableButton() {
      return this.disabled || this.selectedId === undefined || this.isMoving;
    },
  },
  watch: {
    destinationNamespaces(namespaces) {
      this.updateDestinationNamespacesCache(namespaces);
    },
  },
  created() {
    this.setSearchTermDebounced = debounce(this.setSearchTerm, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    setSearchTerm(searchTerm) {
      this.searchTerm = searchTerm;
    },
    clearSearch() {
      this.searchTerm = '';
      this.$refs.listbox.$refs.searchBox.clearInput?.();
    },
    handleShown() {
      this.searchStarted = true;
    },
    handleSelect(item) {
      this.selectedId = item;
      this.clearSearch();
    },
    reset() {
      this.handleSelect(undefined);
      this.$refs.listbox.close();
    },
    async handleMove() {
      this.isMoving = true;
      this.$emit('moveStart');
      const totalCount = this.checkedItems.length;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: workItemBulkMoveMutation,
          variables: {
            input: {
              ids: this.checkedItems.map((item) => item.id),
              sourceFullPath: this.fullPath,
              targetFullPath: this.selectedNamespace.fullPath,
            },
          },
        });
        const { errors, movedWorkItemCount } = data.workItemBulkMove;
        if (errors.length > 0) {
          throw new Error(errors[0]);
        }
        const toastMessage = sprintf(
          s__('WorkItem|Moved %{movedWorkItemCount} of %{totalCount} items'),
          {
            movedWorkItemCount,
            totalCount,
          },
        );
        this.$emit('moveSuccess', { toastMessage });
      } catch (error) {
        createAlert({
          message: s__('WorkItem|Something went wrong while bulk editing.'),
          captureError: true,
          error,
        });
      } finally {
        this.isMoving = false;
        this.$emit('moveFinish');
      }
    },
    updateDestinationNamespacesCache(namespaces) {
      // Need to store all users we encounter so we can show "Selected" users
      // even if they're not found in the apollo `users` list
      this.destinationNamespacesCache = unionBy(this.destinationNamespacesCache, namespaces, 'id');
    },
  },
};
</script>

<template>
  <gl-form-group :label="__('Move')">
    <gl-collapsible-listbox
      ref="listbox"
      block
      :header-text="s__('WorkItem|Select destination')"
      is-check-centered
      :items="listboxItems"
      :no-results-text="s__('WorkItem|No matching results')"
      :reset-button-label="__('Reset')"
      searchable
      :searching="isLoading"
      :selected="selectedId"
      :toggle-text="toggleText"
      :disabled="disabled || isMoving || hasNoItems"
      @reset="reset"
      @search="setSearchTermDebounced"
      @select="handleSelect"
      @shown="handleShown"
    />
    <gl-button
      data-testid="submit-move-button"
      :disabled="shouldDisableButton"
      block
      class="gl-mt-3"
      :loading="isMoving"
      @click="handleMove"
      >{{ buttonText }}</gl-button
    >
  </gl-form-group>
</template>
