<script>
import { GlIcon, GlLink, GlSprintf, GlTableLite, GlPopover } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import { sprintf } from '~/locale';
import {
  HELP_LINK_ARIA_LABEL,
  PROJECT_TABLE_LABEL_STORAGE_TYPE,
  PROJECT_TABLE_LABEL_USAGE,
} from '../../constants';
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
    NumberToHumanSize,
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
      label: PROJECT_TABLE_LABEL_STORAGE_TYPE,
      thClass: 'gl-w-90p',
    },
    {
      key: 'value',
      label: PROJECT_TABLE_LABEL_USAGE,
      thClass: 'gl-w-10p',
    },
  ],
};
</script>
<template>
  <gl-table-lite :items="storageTypes" :fields="$options.projectTableFields">
    <template #cell(storageType)="{ item }">
      <div class="gl-display-flex gl-flex-direction-row">
        <storage-type-icon :name="item.id" :data-testid="`${item.id}-icon`" />
        <div>
          <p class="gl-font-weight-bold gl-mb-0" :data-testid="`${item.id}-name`">
            <gl-link
              v-if="item.detailsPath && item.value"
              :data-testid="`${item.id}-details-link`"
              :href="item.detailsPath"
              >{{ item.name }}</gl-link
            >
            <template v-else>
              {{ item.name }}
            </template>
            <gl-link
              v-if="item.helpPath"
              :href="item.helpPath"
              target="_blank"
              :aria-label="helpLinkAriaLabel(item.name)"
              :data-testid="`${item.id}-help-link`"
            >
              <gl-icon name="question-o" :size="12" />
            </gl-link>
          </p>
          <p class="gl-mb-0" :data-testid="`${item.id}-description`">
            {{ item.description }}
          </p>
          <p v-if="item.warningMessage" class="gl-mb-0 gl-font-sm">
            <gl-icon name="warning" :size="12" />
            <gl-sprintf :message="item.warningMessage">
              <template #warningLink="{ content }">
                <gl-link :href="item.warningLink" target="_blank" class="gl-font-sm">{{
                  content
                }}</gl-link>
              </template>
            </gl-sprintf>
          </p>
        </div>
      </div>
    </template>

    <template #cell(value)="{ item }">
      <number-to-human-size :value="item.value" :data-testid="item.id + '-value'" />

      <template v-if="item.warning">
        <gl-icon
          :id="item.id + '-warning-icon'"
          name="warning"
          class="gl-mt-2 gl-lg-mt-0 gl-lg-ml-2"
          :data-testid="item.id + '-warning-icon'"
        />
        <gl-popover
          triggers="hover focus"
          placement="top"
          :target="item.id + '-warning-icon'"
          :content="item.warning.popoverContent"
          :data-testid="item.id + '-popover'"
        />
      </template>
    </template>
  </gl-table-lite>
</template>
