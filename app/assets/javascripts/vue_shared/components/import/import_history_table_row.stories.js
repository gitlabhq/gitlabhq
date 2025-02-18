import { GlTooltipDirective } from '@gitlab/ui';

import ImportHistoryTableRow from './import_history_table_row.vue';

export default {
  component: ImportHistoryTableRow,
  title: 'vue_shared/import/import_history_table_row',
};

const defaultProps = {
  showToggle: true,
  isNested: false,
  gridClasses: '',
};

const Template = (args, { argTypes }) => ({
  components: { ImportHistoryTableRow },
  directives: { GlTooltip: GlTooltipDirective },
  props: Object.keys(argTypes),
  placeholderClasses:
    'gl-flex gl-border gl-border-dashed gl-p-4 gl-text-subtle gl-rounded-base gl-text-sm gl-bg-subtle',
  template: `<div>
  <import-history-table-row v-bind="$props">
  <template #checkbox>
    <div :class="$options.placeholderClasses" v-gl-tooltip title="CHECKBOX SLOT"></div>
  </template>
  <template #column-1>
    <div :class="$options.placeholderClasses">COLUMN-1 SLOT</div>
  </template>
  <template #column-2>
    <div :class="$options.placeholderClasses">COLUMN-2 SLOT</div>
  </template>
  <template #column-3>
    <div :class="$options.placeholderClasses">COLUMN-3 SLOT</div>
  </template>
  <template #column-4>
    <div :class="$options.placeholderClasses">COLUMN-4 SLOT</div>
  </template>
  <template #nested-row>
    <div :class="$options.placeholderClasses">NESTED-ROW SLOT OR EXPANDED-CONTENT SLOT</div>
  </template>
  <template #expanded-content>
    <div :class="$options.placeholderClasses">EXPANDED-CONTENT SLOT</div>
  </template>
  </import-history-table-row>
</div>`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
