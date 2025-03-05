import { GlButton, GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import { basic } from 'jest/vue_shared/components/import/source_list_mock_data';
import ImportSourceListTable from './import_source_list_table.vue';

export default {
  component: ImportSourceListTable,
  title: 'vue_shared/import/import_source_list_table',
};

const defaultProps = basic;

const Template = (args, { argTypes }) => ({
  components: { ImportSourceListTable, GlButton },
  directives: { GlTooltip: GlTooltipDirective },
  props: Object.keys(argTypes),
  placeholderClasses:
    'gl-flex gl-border gl-border-dashed gl-p-4 gl-text-subtle gl-rounded-base gl-text-sm gl-bg-subtle',
  template: `<div>
  <import-source-list-table v-bind="$props">
    <template #select-all-checkbox="{ items }">
      <div :class="$options.placeholderClasses" class="!gl-p-3" v-gl-tooltip title="CHECKBOX SLOT"></div>
    </template>
    <template #row-checkbox="{ item }">
      <div :class="$options.placeholderClasses" class="!gl-p-3" v-gl-tooltip title="CHECKBOX SLOT"></div>
    </template>
    <template #destination-input="{ item }">
      <div :class="$options.placeholderClasses">DESTINATION INPUT GOES HERE</div>
    </template>
    <template #action="{ item }">
      <div :class="$options.placeholderClasses">ACTION GOES HERE</div>
    </template>
  </import-source-list-table>
</div>`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
Default.parameters = {
  docs: {
    description: {
      story: `This is a bare-bones example of the import source list table component.`,
    },
  },
};

const FunctionalExample = (args, { argTypes }) => ({
  components: { ImportSourceListTable, GlButton, GlFormCheckbox },
  data() {
    return {
      selectedItems: [],
    };
  },
  props: Object.keys(argTypes),
  computed: {
    totalSelectable() {
      return this.items.filter((i) => !i.full_path).length;
    },
    selectAllIndeterminate() {
      return this.selectedItems.length > 0 && this.selectedItems.length < this.totalSelectable;
    },
    numberToImport() {
      if (this.selectedItems.length === 0) {
        return this.totalSelectable;
      }

      return this.selectedItems.length;
    },
    allSelected() {
      return this.selectedItems.length === this.totalSelectable;
    },
  },
  methods: {
    isSelected(id) {
      return this.selectedItems.includes(id);
    },
    toggleSelect(id) {
      if (this.isSelected(id)) {
        this.selectedItems = this.selectedItems.filter((i) => i !== id);
      } else {
        this.selectedItems.push(id);
      }
    },
    selectAll(checked) {
      if (checked) {
        this.selectedItems = this.items.filter((i) => !i.full_path).map((i) => i.id);
      } else {
        this.selectedItems = [];
      }
    },
  },
  placeholderClasses:
    'gl-flex gl-border gl-border-dashed gl-p-4 gl-text-subtle gl-rounded-base gl-text-sm gl-bg-subtle',
  template: `<div>
  <div class="gl-flex gl-bg-subtle gl-justify-end gl-p-5">
    <gl-button variant="confirm">Import {{ numberToImport }} repositor{{ numberToImport === 1 ? 'y' : 'ies' }}</gl-button>
  </div>
  <import-source-list-table v-bind="$props">
    <template #select-all-checkbox="{ items }">
      <gl-form-checkbox class="gl-min-h-5 gl-w-0" @change="selectAll" :indeterminate="selectAllIndeterminate" :checked="allSelected" />
    </template>
    <template #row-checkbox="{ item }">
      <gl-form-checkbox class="gl-min-h-5 gl-w-0" :checked="isSelected(item.id)" @change="toggleSelect(item.id)" />
    </template>
    <template #destination-input="{ item }">
      <div :class="$options.placeholderClasses">DESTINATION INPUT GOES HERE</div>
    </template>
    <template #action="{ item }">
      <gl-button v-if="item.action" v-bind="item.action.buttonProps">{{
        item.action.label
      }}</gl-button>
    </template>
  </import-source-list-table>
</div>`,
});

export const Functional = FunctionalExample.bind({});
Functional.args = defaultProps;

Functional.parameters = {
  docs: {
    description: {
      story: `This example shows an import source table that includes functional multi-select and examples of the import action buttons.
      
Note that the top bar with an Import button was added separately and is not part of the table.`,
    },
  },
};
