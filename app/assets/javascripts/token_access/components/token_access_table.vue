<script>
import { GlButton, GlTableLite } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlTableLite,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  props: {
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    items: {
      type: Array,
      required: true,
    },
    tableFields: {
      type: Array,
      required: true,
    },
  },
  computed: {
    emptyText() {
      return sprintf(s__('CI/CD|No %{itemType}s have been added to the scope'), {
        itemType: this.itemType,
      });
    },
    itemType() {
      return this.isGroup ? 'group' : 'project';
    },
  },
};
</script>
<template>
  <gl-table-lite
    :items="items"
    :fields="tableFields"
    :tbody-tr-attr="{ 'data-testid': `${itemType}s-token-table-row` }"
    :empty-text="emptyText"
    show-empty
    stacked="sm"
    thead-class="gl-display-none"
    fixed
  >
    <template #cell(fullPath)="{ item }">
      <span :data-testid="`token-access-${itemType}-name`">{{ item.fullPath }}</span>
    </template>

    <template #cell(actions)="{ item }">
      <gl-button
        v-if="item.fullPath !== fullPath"
        category="primary"
        icon="remove"
        :aria-label="__('Remove access')"
        @click="$emit('removeItem', item)"
      />
    </template>
  </gl-table-lite>
</template>
