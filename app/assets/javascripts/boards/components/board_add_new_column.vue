<script>
import {
  GlTooltipDirective as GlTooltip,
  GlButton,
  GlCollapsibleListbox,
  GlIcon,
} from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import { __ } from '~/locale';

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
  inject: ['scopedLabelsAvailable'],
  data() {
    return {
      selectedId: null,
      selectedLabel: null,
      selectedIdValid: true,
    };
  },
  computed: {
    ...mapState(['labels', 'labelsLoading']),
    ...mapGetters(['getListByLabelId']),
    columnForSelected() {
      return this.getListByLabelId(this.selectedId);
    },
    items() {
      return (
        this.labels.map((i) => ({
          ...i,
          text: i.title,
          value: i.id,
        })) || []
      );
    },
  },
  created() {
    this.filterItems();
  },
  methods: {
    ...mapActions(['createList', 'fetchLabels', 'highlightList', 'setAddColumnFormVisibility']),
    addList() {
      if (!this.selectedLabel) {
        this.selectedIdValid = false;
        return;
      }

      this.setAddColumnFormVisibility(false);

      if (this.columnForSelected) {
        const listId = this.columnForSelected.id;
        this.highlightList(listId);
        return;
      }

      this.createList({ labelId: this.selectedId });
    },

    filterItems(searchTerm) {
      this.fetchLabels(searchTerm);
    },

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
    @filter-items="filterItems"
    @add-list="addList"
  >
    <template #dropdown>
      <gl-collapsible-listbox
        class="gl-mb-3 gl-max-w-full"
        :items="items"
        searchable
        :search-placeholder="__('Search labels')"
        :searching="labelsLoading"
        :selected="selectedId"
        :no-results-text="$options.i18n.noResults"
        @select="setSelectedItem"
        @search="filterItems"
        @hidden="onHide"
      >
        <template #toggle>
          <gl-button
            class="gl-max-w-full gl-display-flex gl-align-items-center gl-text-truncate"
            :class="{ 'gl-inset-border-1-red-400!': !selectedIdValid }"
            button-text-classes="gl-display-flex"
          >
            <template v-if="selectedLabel">
              <span
                class="dropdown-label-box gl-top-0 gl-flex-shrink-0"
                :style="{
                  backgroundColor: selectedLabel.color,
                }"
              ></span>
              <div class="gl-text-truncate">{{ selectedLabel.title }}</div>
            </template>

            <template v-else>{{ __('Select a label') }}</template>
            <gl-icon class="dropdown-chevron gl-ml-2" name="chevron-down" />
          </gl-button>
        </template>

        <template #list-item="{ item }">
          <label class="gl-display-flex gl-font-weight-normal gl-overflow-break-word gl-mb-0">
            <span
              class="dropdown-label-box gl-top-0 gl-flex-shrink-0"
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
