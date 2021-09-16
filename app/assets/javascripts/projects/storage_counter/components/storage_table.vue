<script>
import { GlLink, GlIcon, GlTable, GlSprintf } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { thWidthClass } from '~/lib/utils/table_utility';
import { sprintf } from '~/locale';
import { PROJECT_TABLE_LABELS, HELP_LINK_ARIA_LABEL } from '../constants';

export default {
  name: 'StorageTable',
  components: {
    GlLink,
    GlIcon,
    GlTable,
    GlSprintf,
  },
  props: {
    storageTypes: {
      type: Array,
      required: true,
    },
  },
  methods: {
    helpLinkAriaLabel(linkTitle) {
      return sprintf(HELP_LINK_ARIA_LABEL, {
        linkTitle,
      });
    },
  },
  projectTableFields: [
    {
      key: 'storageType',
      label: PROJECT_TABLE_LABELS.STORAGE_TYPE,
      thClass: thWidthClass(90),
      sortable: true,
    },
    {
      key: 'value',
      label: PROJECT_TABLE_LABELS.VALUE,
      thClass: thWidthClass(10),
      sortable: true,
      formatter: (value) => {
        return numberToHumanSize(value, 1);
      },
    },
  ],
};
</script>
<template>
  <gl-table :items="storageTypes" :fields="$options.projectTableFields">
    <template #cell(storageType)="{ item }">
      <p class="gl-font-weight-bold gl-mb-0" :data-testid="`${item.storageType.id}-name`">
        {{ item.storageType.name }}
        <gl-link
          v-if="item.storageType.helpPath"
          :href="item.storageType.helpPath"
          target="_blank"
          :aria-label="helpLinkAriaLabel(item.storageType.name)"
          :data-testid="`${item.storageType.id}-help-link`"
        >
          <gl-icon name="question" :size="12" />
        </gl-link>
      </p>
      <p class="gl-mb-0" :data-testid="`${item.storageType.id}-description`">
        {{ item.storageType.description }}
      </p>
      <p v-if="item.storageType.warningMessage" class="gl-mb-0 gl-font-sm">
        <gl-icon name="warning" :size="12" />
        <gl-sprintf :message="item.storageType.warningMessage">
          <template #warningLink="{ content }">
            <gl-link :href="item.storageType.warningLink" target="_blank" class="gl-font-sm">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </gl-table>
</template>
