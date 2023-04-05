<script>
import { GlIcon, GlLink, GlSprintf, GlTableLite, GlPopover } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { thWidthPercent } from '~/lib/utils/table_utility';
import { sprintf } from '~/locale';
import {
  HELP_LINK_ARIA_LABEL,
  PROJECT_TABLE_LABEL_STORAGE_TYPE,
  PROJECT_TABLE_LABEL_USAGE,
  containerRegistryId,
  containerRegistryPopoverId,
} from '../constants';
import { descendingStorageUsageSort } from '../utils';
import StorageTypeIcon from './storage_type_icon.vue';

export default {
  name: 'ProjectStorageDetail',
  components: {
    GlLink,
    GlIcon,
    GlTableLite,
    GlSprintf,
    StorageTypeIcon,
    GlPopover,
  },
  inject: ['containerRegistryPopoverContent'],
  props: {
    storageTypes: {
      type: Array,
      required: true,
    },
  },
  computed: {
    sizeSortedStorageTypes() {
      const warnings = {
        [containerRegistryId]: {
          popoverId: containerRegistryPopoverId,
          popoverContent: this.containerRegistryPopoverContent,
        },
      };

      return this.storageTypes
        .map((type) => {
          const warning = warnings[type.storageType.id] || null;
          return {
            warning,
            ...type,
          };
        })
        .sort(descendingStorageUsageSort('value'));
    },
  },
  methods: {
    helpLinkAriaLabel(linkTitle) {
      return sprintf(HELP_LINK_ARIA_LABEL, {
        linkTitle,
      });
    },
    numberToHumanSize,
  },
  projectTableFields: [
    {
      key: 'storageType',
      label: PROJECT_TABLE_LABEL_STORAGE_TYPE,
      thClass: thWidthPercent(90),
    },
    {
      key: 'value',
      label: PROJECT_TABLE_LABEL_USAGE,
      thClass: thWidthPercent(10),
    },
  ],
};
</script>
<template>
  <gl-table-lite :items="sizeSortedStorageTypes" :fields="$options.projectTableFields">
    <template #cell(storageType)="{ item }">
      <div class="gl-display-flex gl-flex-direction-row">
        <storage-type-icon
          :name="item.storageType.id"
          :data-testid="`${item.storageType.id}-icon`"
        />
        <div>
          <p class="gl-font-weight-bold gl-mb-0" :data-testid="`${item.storageType.id}-name`">
            {{ item.storageType.name }}
            <gl-link
              v-if="item.storageType.helpPath"
              :href="item.storageType.helpPath"
              target="_blank"
              :aria-label="helpLinkAriaLabel(item.storageType.name)"
              :data-testid="`${item.storageType.id}-help-link`"
            >
              <gl-icon name="question-o" :size="12" />
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
        </div>
      </div>
    </template>

    <template #cell(value)="{ item }">
      {{ numberToHumanSize(item.value, 1) }}

      <template v-if="item.warning">
        <gl-icon
          :id="item.warning.popoverId"
          name="warning"
          class="gl-mt-2 gl-lg-mt-0 gl-lg-ml-2"
        />
        <gl-popover
          triggers="hover focus"
          placement="top"
          :target="item.warning.popoverId"
          :content="item.warning.popoverContent"
          :data-testid="item.warning.popoverId"
        />
      </template>
    </template>
  </gl-table-lite>
</template>
