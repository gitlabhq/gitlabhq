<script>
import produce from 'immer';
import { debounce } from 'lodash';
import {
  GlTooltipDirective as GlTooltip,
  GlButton,
  GlCollapsibleListbox,
  GlIcon,
} from '@gitlab/ui';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import { __, s__ } from '~/locale';
import { createListMutations, listsQuery, BoardType, ListType } from 'ee_else_ce/boards/constants';
import boardLabelsQuery from '../graphql/board_labels.query.graphql';
import { setError } from '../graphql/cache_updates';
import { getListByTypeId } from '../boards_util';

export default {
  i18n: {
    value: __('Value'),
    noResults: __('No matching results'),
  },
  components: {
    BoardAddNewColumnForm,
    GlButton,
    GlCollapsibleListbox,
    GlIcon,
  },
  directives: {
    GlTooltip,
  },
  inject: ['scopedLabelsAvailable', 'issuableType', 'fullPath', 'boardType'],
  props: {
    listQueryVariables: {
      type: Object,
      required: true,
    },
    boardId: {
      type: String,
      required: true,
    },
    lists: {
      type: Object,
      required: true,
    },
    position: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedId: null,
      selectedLabel: null,
      selectedIdValid: true,
      labels: [],
      searchTerm: '',
    };
  },
  apollo: {
    labels: {
      query: boardLabelsQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          searchTerm: this.searchTerm,
          isGroup: this.boardType === BoardType.group,
          isProject: this.boardType === BoardType.project,
        };
      },
      update(data) {
        return data[this.boardType].labels.nodes;
      },
      error(error) {
        setError({
          error,
          message: s__('Boards|An error occurred while fetching labels. Please try again.'),
        });
      },
    },
  },
  computed: {
    isLabelsLoading() {
      return this.$apollo.queries.labels.loading;
    },
    columnForSelected() {
      return getListByTypeId(this.lists, ListType.label, this.selectedId);
    },
    items() {
      return (this.labels || []).map((i) => ({
        ...i,
        text: i.title,
        value: i.id,
      }));
    },
  },
  methods: {
    async createList({ labelId, position }) {
      try {
        await this.$apollo.mutate({
          mutation: createListMutations[this.issuableType].mutation,
          variables: {
            labelId,
            boardId: this.boardId,
            position,
          },
          update: (
            store,
            {
              data: {
                boardListCreate: { list },
              },
            },
          ) => {
            const sourceData = store.readQuery({
              query: listsQuery[this.issuableType].query,
              variables: this.listQueryVariables,
            });
            const data = produce(sourceData, (draft) => {
              const lists = draft[this.boardType].board.lists.nodes;
              if (position === null) {
                lists.push({ ...list, position: lists.length });
              } else {
                const updatedLists = lists.map((l) => {
                  if (l.position >= position) {
                    return { ...l, position: l.position + 1 };
                  }
                  return l;
                });
                updatedLists.splice(position, 0, list);
                draft[this.boardType].board.lists.nodes = updatedLists;
              }
            });
            store.writeQuery({
              query: listsQuery[this.issuableType].query,
              variables: this.listQueryVariables,
              data,
            });
            this.$emit('highlight-list', list.id);
          },
        });
      } catch (error) {
        setError({
          error,
          message: s__('Boards|An error occurred while creating the list. Please try again.'),
        });
      }
    },
    async addList() {
      if (!this.selectedLabel) {
        this.selectedIdValid = false;
        return;
      }

      if (this.columnForSelected) {
        const listId = this.columnForSelected.id;
        this.$emit('highlight-list', listId);
        return;
      }

      await this.createList({ labelId: this.selectedId, position: this.position });
      this.$emit('setAddColumnFormVisibility', false);
    },

    onSearch: debounce(function debouncedSearch(searchTerm) {
      this.searchTerm = searchTerm;
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),

    setSelectedItem(selectedId) {
      this.selectedId = selectedId;

      const label = this.labels.find(({ id }) => id === selectedId);
      if (!selectedId || !label) {
        this.selectedLabel = null;
      } else {
        this.selectedLabel = { ...label };
      }
    },
    onHide() {
      this.searchValue = '';
      this.$emit('filter-items', '');
      this.$emit('hide');
    },
  },
};
</script>

<template>
  <board-add-new-column-form
    :selected-id-valid="selectedIdValid"
    @add-list="addList"
    @setAddColumnFormVisibility="$emit('setAddColumnFormVisibility', $event)"
  >
    <template #dropdown>
      <gl-collapsible-listbox
        class="gl-mb-3 gl-max-w-full"
        :items="items"
        searchable
        :search-placeholder="__('Search labels')"
        :searching="isLabelsLoading"
        :selected="selectedId"
        :no-results-text="$options.i18n.noResults"
        @select="setSelectedItem"
        @search="onSearch"
        @hidden="onHide"
      >
        <template #toggle>
          <gl-button
            class="gl-flex gl-max-w-full gl-items-center gl-truncate"
            :class="{ '!gl-shadow-inner-1-red-400': !selectedIdValid }"
            button-text-classes="gl-flex"
          >
            <template v-if="selectedLabel">
              <span
                class="dropdown-label-box gl-top-0 gl-shrink-0"
                :style="{
                  backgroundColor: selectedLabel.color,
                }"
              ></span>
              <div class="gl-truncate">{{ selectedLabel.title }}</div>
            </template>

            <template v-else>{{ __('Select a label') }}</template>
            <gl-icon class="dropdown-chevron gl-ml-2" name="chevron-down" />
          </gl-button>
        </template>

        <template #list-item="{ item }">
          <label class="gl-mb-0 gl-flex gl-hyphens-auto gl-break-words gl-font-normal">
            <span
              class="dropdown-label-box gl-top-0 gl-shrink-0"
              :style="{
                backgroundColor: item.color,
              }"
            ></span>
            <span>{{ item.title }}</span>
          </label>
        </template>
      </gl-collapsible-listbox>
    </template>
  </board-add-new-column-form>
</template>
