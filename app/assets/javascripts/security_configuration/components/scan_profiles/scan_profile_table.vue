<script>
import {
  GlTableLite,
  GlButtonGroup,
  GlButton,
  GlIcon,
  GlTooltipDirective,
  GlLink,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { PROMO_URL } from '~/constants';
import { SCAN_PROFILE_CATEGORIES, SCAN_PROFILE_I18N } from '~/security_configuration/constants';

export default {
  name: 'ScanProfileTable',
  components: {
    GlTableLite,
    GlButtonGroup,
    GlButton,
    GlIcon,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tableItems: {
      type: Array,
      required: true,
    },
  },
  computed: {
    tableFields() {
      return [
        { key: 'scanType', label: __('Scanner') },
        { key: 'name', label: __('Profile'), tdClass: '!gl-align-middle' },
        { key: 'status', label: __('Status'), tdClass: '!gl-align-middle' },
        { key: 'lastScan', label: __('Last scan'), tdClass: '!gl-align-middle' },
        { key: 'actions', label: '' },
      ];
    },
  },
  methods: {
    getScannerMetadata(scanType) {
      return SCAN_PROFILE_CATEGORIES[scanType] || {};
    },
  },
  LEARN_MORE_LINK: `${PROMO_URL}/solutions/application-security-testing/`,
  SCAN_PROFILE_I18N,
};
</script>

<template>
  <gl-table-lite :items="tableItems" :fields="tableFields" stacked="sm">
    <template #head(name)="data">
      <div class="gl-flex gl-items-center">
        <span>{{ data.label }}</span>
        <gl-icon
          v-gl-tooltip
          name="information-o"
          :title="$options.SCAN_PROFILE_I18N.profilesDefine"
          class="gl-ml-2 gl-text-secondary"
        />
      </div>
    </template>

    <template #cell(scanType)="{ item }">
      <div class="gl-flex gl-items-center">
        <div
          class="gl-border gl-mr-3 gl-flex gl-items-center gl-justify-center gl-rounded-base gl-p-2"
          :class="
            item.isConfigured
              ? 'gl-border-feedback-success gl-bg-feedback-success gl-text-feedback-success'
              : 'gl-border-dashed gl-bg-white gl-text-feedback-neutral'
          "
          style="width: 32px; height: 32px"
        >
          <span class="gl-font-weight-bold gl-font-sm">{{
            getScannerMetadata(item.scanType).label
          }}</span>
        </div>
        <span class="gl-font-bold">{{ getScannerMetadata(item.scanType).name }}</span>
        <gl-icon
          v-gl-tooltip
          name="information-o"
          variant="info"
          :title="getScannerMetadata(item.scanType).tooltip"
          class="gl-ml-2"
        />
      </div>
    </template>

    <template #cell(name)="{ item }">
      <slot v-if="$scopedSlots['cell(name)']" name="cell(name)" v-bind="{ item }"></slot>
      <div v-else class="gl-flex gl-items-center">
        <span class="gl-text-secondary">
          {{ $options.SCAN_PROFILE_I18N.noProfile }}
        </span>
      </div>
    </template>

    <template #cell(status)="{ item }">
      <slot v-if="$scopedSlots['cell(status)']" name="cell(status)" v-bind="{ item }"></slot>
      <div v-else class="gl-flex gl-flex-col">
        <span class="gl-font-weight-bold">
          {{ __('Available with Ultimate') }}
        </span>
        <span class="gl-mt-1 gl-text-sm gl-text-secondary">
          <gl-link :href="$options.LEARN_MORE_LINK" target="_blank">
            {{ __('Learn more about the Ultimate security suite') }}
            <gl-icon name="external-link" :aria-label="__('(external link)')" />
          </gl-link>
        </span>
      </div>
    </template>

    <template #cell(lastScan)="{ item }">
      <span>{{ item.lastScan || '—' }}</span>
    </template>

    <template #cell(actions)="{ item }">
      <slot v-if="$scopedSlots['cell(actions)']" name="cell(actions)" v-bind="{ item }"></slot>
      <div v-else>
        <gl-button-group>
          <!-- Apply button -->
          <gl-button variant="confirm" category="secondary" disabled>
            {{ $options.SCAN_PROFILE_I18N.applyDefault }}
          </gl-button>
          <!-- Preview button -->
          <gl-button variant="confirm" category="secondary" icon="eye" disabled />
        </gl-button-group>
      </div>
    </template>
  </gl-table-lite>
</template>
