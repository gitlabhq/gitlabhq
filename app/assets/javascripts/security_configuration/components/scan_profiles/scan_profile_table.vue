<script>
import {
  GlTable,
  GlButtonGroup,
  GlButton,
  GlIcon,
  GlPopover,
  GlLink,
  GlSkeletonLoader,
  GlSprintf,
} from '@gitlab/ui';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { InternalEvents } from '~/tracking';
import {
  SCAN_PROFILE_I18N,
  EVENT_VIEW_SCAN_PROFILE_TABLE,
  EVENT_CLICK_SCAN_PROFILE_LEARN_MORE_LINK,
} from '~/security_configuration/constants';
import ScanTypeCell from '~/security_configuration/components/scan_profiles/scan_type_cell.vue';

export default {
  name: 'ScanProfileTable',
  components: {
    GlTable,
    GlButtonGroup,
    GlButton,
    GlIcon,
    GlPopover,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
    ScanTypeCell,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    tableItems: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tableFields() {
      return [
        { key: 'scanType', label: __('Scanner') },
        { key: 'name', label: __('Profile'), tdClass: '!gl-align-middle' },
        { key: 'status', label: __('Scanner health'), tdClass: '!gl-align-middle' },
        { key: 'lastScan', label: __('Last scan'), tdClass: '!gl-align-middle' },
        { key: 'actions', label: '' },
      ];
    },
    scanProfileHelpPath() {
      return helpPagePath(
        '/user/application_security/configuration/security_configuration_profiles',
      );
    },
  },
  mounted() {
    this.trackEvent(EVENT_VIEW_SCAN_PROFILE_TABLE);
  },
  EVENT_CLICK_SCAN_PROFILE_LEARN_MORE_LINK,
  SCAN_PROFILE_I18N,
};
</script>

<template>
  <gl-table :items="tableItems" :fields="tableFields" stacked="sm" :busy="loading">
    <template #table-busy>
      <gl-skeleton-loader :width="490" :height="35">
        <rect width="105" height="15" rx="4" />
        <rect x="110" width="120" height="15" rx="4" />
        <rect x="235" width="90" height="15" rx="4" />
        <rect x="330" width="105" height="15" rx="4" />
        <rect x="440" width="50" height="15" rx="4" />

        <rect y="20" width="105" height="15" rx="4" />
        <rect y="20" x="110" width="120" height="15" rx="4" />
        <rect y="20" x="235" width="90" height="15" rx="4" />
        <rect y="20" x="330" width="105" height="15" rx="4" />
        <rect y="20" x="440" width="50" height="15" rx="4" />
      </gl-skeleton-loader>
    </template>

    <template #head(name)="data">
      <div class="gl-flex gl-items-center">
        <span>{{ data.label }}</span>
        <gl-icon
          id="profile-info-icon"
          name="information-o"
          variant="info"
          class="gl-ml-2 gl-text-subtle"
        />
        <gl-popover
          target="profile-info-icon"
          placement="top"
          :title="$options.SCAN_PROFILE_I18N.profileHelpTitle"
        >
          <gl-sprintf :message="$options.SCAN_PROFILE_I18N.profileHelpDescription">
            <template #link="{ content }">
              <gl-link
                :href="scanProfileHelpPath"
                target="_blank"
                :data-event-tracking="$options.EVENT_CLICK_SCAN_PROFILE_LEARN_MORE_LINK"
                data-event-label="profile_help"
              >
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </gl-popover>
      </div>
    </template>

    <template #cell(scanType)="{ item }">
      <scan-type-cell
        :scan-type="item.scanType"
        :is-configured="item.isConfigured"
        :status="item.status"
      />
    </template>

    <template #cell(name)="{ item }">
      <slot v-if="$scopedSlots['cell(name)']" name="cell(name)" v-bind="{ item }"></slot>
      <div v-else class="gl-flex gl-items-center">
        <span class="gl-text-subtle">
          {{ $options.SCAN_PROFILE_I18N.noProfile }}
        </span>
      </div>
    </template>

    <template #cell(status)="{ item }">
      <slot v-if="$scopedSlots['cell(status)']" name="cell(status)" v-bind="{ item }"></slot>
      <div v-else class="gl-flex gl-flex-col">
        {{ __('—') }}
      </div>
    </template>

    <template #cell(lastScan)="{ item }">
      <slot v-if="$scopedSlots['cell(last-scan)']" name="cell(last-scan)" v-bind="{ item }"></slot>
      <span v-else>{{ item.lastScan || __('—') }}</span>
    </template>

    <template #cell(actions)="{ item }">
      <slot v-if="$scopedSlots['cell(actions)']" name="cell(actions)" v-bind="{ item }"></slot>
      <div v-else>
        <gl-button-group>
          <!-- Apply button -->
          <gl-button disabled>
            {{ $options.SCAN_PROFILE_I18N.applyDefault }}
          </gl-button>
          <!-- Preview button -->
          <gl-button icon="eye" disabled />
        </gl-button-group>
      </div>
    </template>
  </gl-table>
</template>
