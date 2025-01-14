<script>
import { GlIcon, GlLink, GlSprintf, GlTableLite, GlPopover } from '@gitlab/ui';
import NumberToHumanSize from '~/vue_shared/components/number_to_human_size/number_to_human_size.vue';
import { sprintf, s__ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
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
    HelpIcon,
  },
  props: {
    storageTypes: {
      type: Array,
      required: true,
    },
  },
  methods: {
    helpLinkAriaLabel(linkTitle) {
      return sprintf(s__('UsageQuota|%{linkTitle} help link'), {
        linkTitle,
      });
    },
  },
  projectTableFields: [
    {
      key: 'storageType',
      label: s__('UsageQuota|Storage type'),
      thClass: 'gl-w-9/10',
    },
    {
      key: 'value',
      label: s__('UsageQuota|Usage'),
      thClass: 'gl-w-1/10',
    },
  ],
};
</script>
<template>
  <gl-table-lite :items="storageTypes" :fields="$options.projectTableFields">
    <template #cell(storageType)="{ item }">
      <div class="gl-flex gl-flex-row">
        <storage-type-icon :name="item.id" :data-testid="`${item.id}-icon`" />
        <div class="gl-flex gl-flex-col gl-gap-2">
          <h3
            class="gl-mb-0 gl-mt-2 gl-inline-flex gl-items-center gl-gap-2 gl-text-lg"
            :data-testid="`${item.id}-name`"
          >
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
              class="gl-inline-flex"
              :aria-label="helpLinkAriaLabel(item.name)"
              :data-testid="`${item.id}-help-link`"
            >
              <help-icon />
            </gl-link>
          </h3>
          <p class="gl-mb-0 gl-text-subtle" :data-testid="`${item.id}-description`">
            {{ item.description }}
          </p>
          <p v-if="item.warningMessage" class="gl-mb-0 gl-text-sm">
            <gl-icon name="warning" :size="12" />
            <gl-sprintf :message="item.warningMessage">
              <template #warningLink="{ content }">
                <gl-link :href="item.warningLink" target="_blank" class="gl-text-sm">{{
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
          class="gl-mt-2 lg:gl-ml-2 lg:gl-mt-0"
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
