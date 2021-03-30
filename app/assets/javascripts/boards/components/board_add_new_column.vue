<script>
import { GlFormRadio, GlFormRadioGroup, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import { ListType } from '~/boards/constants';
import boardsStore from '~/boards/stores/boards_store';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  components: {
    BoardAddNewColumnForm,
    GlFormRadio,
    GlFormRadioGroup,
  },
  directives: {
    GlTooltip,
  },
  inject: ['scopedLabelsAvailable'],
  data() {
    return {
      selectedId: null,
      selectedLabel: null,
    };
  },
  computed: {
    ...mapState(['labels', 'labelsLoading']),
    ...mapGetters(['getListByLabelId', 'shouldUseGraphQL']),
    columnForSelected() {
      return this.getListByLabelId(this.selectedId);
    },
  },
  created() {
    this.filterItems();
  },
  methods: {
    ...mapActions(['createList', 'fetchLabels', 'highlightList', 'setAddColumnFormVisibility']),
    highlight(listId) {
      if (this.shouldUseGraphQL) {
        this.highlightList(listId);
      } else {
        const list = boardsStore.state.lists.find(({ id }) => id === listId);
        list.highlighted = true;
        setTimeout(() => {
          list.highlighted = false;
        }, 2000);
      }
    },
    addList() {
      if (!this.selectedLabel) {
        return;
      }

      this.setAddColumnFormVisibility(false);

      if (this.columnForSelected) {
        const listId = this.columnForSelected.id;
        this.highlight(listId);
        return;
      }

      if (this.shouldUseGraphQL) {
        this.createList({ labelId: this.selectedId });
      } else {
        const listObj = {
          labelId: getIdFromGraphQLId(this.selectedId),
          title: this.selectedLabel.title,
          position: boardsStore.state.lists.length - 2,
          list_type: ListType.label,
          label: this.selectedLabel,
        };

        boardsStore.new(listObj);
      }
    },

    filterItems(searchTerm) {
      this.fetchLabels(searchTerm);
    },

    setSelectedItem(selectedId) {
      const label = this.labels.find(({ id }) => id === selectedId);
      if (!selectedId || !label) {
        this.selectedLabel = null;
      } else {
        this.selectedLabel = { ...label };
      }
    },
  },
};
</script>

<template>
  <board-add-new-column-form
    :loading="labelsLoading"
    :none-selected="__('Select a label')"
    :search-placeholder="__('Search labels')"
    :selected-id="selectedId"
    @filter-items="filterItems"
    @add-list="addList"
  >
    <template #selected>
      <template v-if="selectedLabel">
        <span
          class="dropdown-label-box gl-top-0 gl-flex-shrink-0"
          :style="{
            backgroundColor: selectedLabel.color,
          }"
        ></span>
        <div class="gl-text-truncate">{{ selectedLabel.title }}</div>
      </template>
    </template>

    <template #items>
      <gl-form-radio-group
        v-if="labels.length > 0"
        v-model="selectedId"
        class="gl-overflow-y-auto gl-px-5 gl-pt-3"
        @change="setSelectedItem"
      >
        <label
          v-for="label in labels"
          :key="label.id"
          class="gl-display-flex gl-mb-5 gl-font-weight-normal gl-overflow-break-word"
        >
          <gl-form-radio :value="label.id" />
          <span
            class="dropdown-label-box gl-top-0 gl-flex-shrink-0"
            :style="{
              backgroundColor: label.color,
            }"
          ></span>
          <span>{{ label.title }}</span>
        </label>
      </gl-form-radio-group>
    </template>
  </board-add-new-column-form>
</template>
