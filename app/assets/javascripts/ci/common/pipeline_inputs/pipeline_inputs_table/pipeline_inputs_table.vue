<script>
import { GlIcon, GlTableLite, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import Markdown from '~/vue_shared/components/markdown/non_gfm_markdown.vue';
import DynamicValueRenderer from './value_column/dynamic_value_renderer.vue';

export default {
  name: 'PipelineInputsTable',
  ARRAY_TYPE: 'ARRAY',
  components: {
    DynamicValueRenderer,
    GlIcon,
    GlTableLite,
    HelpIcon,
    Markdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  fields: [
    {
      key: 'name',
      label: __('Name'),
    },
    {
      key: 'description',
      label: __('Description'),
      tdAttr: { 'data-testid': 'input-description-cell' },
    },
    {
      key: 'type',
      label: __('Type'),
    },
    {
      key: 'value',
      label: __('Value'),
      tdClass: '@md/panel:gl-max-w-26',
    },
  ],
  props: {
    inputs: {
      type: Array,
      required: true,
    },
  },
  emits: ['update'],
  computed: {
    filteredItems() {
      return this.inputs.filter((input) => input.isSelected);
    },
  },
  methods: {
    handleValueUpdated({ item, value }) {
      const updatedInput = { ...item, value };
      this.$emit('update', updatedInput);
    },
    hasDescription(description) {
      return description?.length;
    },
    isArrayType(type) {
      return type === this.$options.ARRAY_TYPE;
    },
  },
};
</script>

<template>
  <!-- Will replace with pagination in the future. -->
  <div class="gl-overflow-y-auto @md/panel:gl-max-h-[50rem]">
    <gl-table-lite
      class="gl-mb-0"
      :items="filteredItems"
      :fields="$options.fields"
      :tbody-tr-attr="{ 'data-testid': 'input-row' }"
      stacked="sm"
    >
      <template #cell(name)="{ item }">
        <span>
          {{ item.name }}
          <span v-if="item.required" class="gl-text-danger" data-testid="required-asterisk">*</span>
        </span>
      </template>
      <template #cell(description)="{ item }">
        <markdown v-if="hasDescription(item.description)" :markdown="item.description" />
        <gl-icon v-else name="dash" :size="12" />
      </template>
      <template #cell(type)="{ item }">
        <span
          >{{ item.type }}
          <help-icon
            v-if="isArrayType(item.type)"
            v-gl-tooltip.hover
            :title="s__('Pipelines|Array values must be in JSON format.')"
          />
        </span>
      </template>
      <template #cell(value)="{ item }">
        <dynamic-value-renderer
          :key="`${item.name}-${item.isSelected}`"
          :item="item"
          @update="handleValueUpdated"
        />
      </template>
    </gl-table-lite>
  </div>
</template>
