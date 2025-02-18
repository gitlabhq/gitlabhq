import { GlTooltipDirective } from '@gitlab/ui';

import ImportHistoryTableHeader from './import_history_table_header.vue';

export default {
  component: ImportHistoryTableHeader,
  title: 'vue_shared/import/import_history_table_header',
};

const defaultProps = {};

const Template = (args, { argTypes }) => ({
  components: { ImportHistoryTableHeader },
  directives: { GlTooltip: GlTooltipDirective },
  props: Object.keys(argTypes),
  placeholderClasses:
    'gl-flex-grow gl-border gl-border-dashed gl-p-4 gl-text-subtle gl-rounded-base gl-text-sm gl-bg-subtle',
  template: `<div>
  <import-history-table-header v-bind="$props">
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
  </import-history-table-header>
</div>`,
});

export const Default = Template.bind({});
Default.args = defaultProps;
