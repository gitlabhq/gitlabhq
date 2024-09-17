<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlToggle,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import isShowingLabelsQuery from '~/graphql_shared/client/is_showing_labels.query.graphql';
import setIsShowingLabelsMutation from '~/graphql_shared/client/set_is_showing_labels.mutation.graphql';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

import Tracking from '~/tracking';
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams, removeParams } from '~/lib/utils/url_utility';
import { GroupByParamType } from 'ee_else_ce/boards/constants';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlToggle,
    LocalStorageSync,
    ToggleEpicsSwimlanes: () => import('ee_component/boards/components/toggle_epics_swimlanes.vue'),
  },
  directives: {
    GlTooltipDirective,
  },
  mixins: [trackingMixin],
  props: {
    showEpicLaneOption: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSwimlanesOn: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isShowingLabels: null,
    };
  },
  apollo: {
    isShowingLabels: {
      query: isShowingLabelsQuery,
      update: (data) => data.isShowingLabels,
    },
  },
  computed: {
    trackProperty() {
      return this.isShowingLabels ? 'on' : 'off';
    },
  },
  methods: {
    onToggleSwimLanes() {
      // Track toggle event
      this.track('click_toggle_swimlanes_button', {
        label: 'toggle_swimlanes',
        property: this.isSwimlanesOn ? 'off' : 'on',
      });

      // Track if the board has swimlane active
      if (!this.isSwimlanesOn) {
        this.track('click_toggle_swimlanes_button', {
          label: 'swimlanes_active',
        });
      }

      this.toggleEpicSwimlanes();
    },
    toggleEpicSwimlanes() {
      if (this.isSwimlanesOn) {
        historyPushState(removeParams(['group_by']), window.location.href, true);
        this.$emit('toggleSwimlanes', false);
      } else {
        historyPushState(
          mergeUrlParams({ group_by: GroupByParamType.epic }, window.location.href, {
            spreadArrays: true,
          }),
        );
        this.$emit('toggleSwimlanes', true);
      }
    },
    setShowLabels() {
      this.$apollo.mutate({
        mutation: setIsShowingLabelsMutation,
        variables: {
          isShowingLabels: !this.isShowingLabels,
        },
      });
    },
  },
  i18n: {
    toggleText: __('View options'),
    showLabels: __('Show labels'),
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-gl-tooltip-directive.hover="$options.i18n.toggleText"
    category="tertiary"
    icon="preferences"
    no-caret
    :toggle-text="$options.i18n.toggleText"
    text-sr-only
    :auto-close="false"
    data-testid="board-options-dropdown"
  >
    <gl-disclosure-dropdown-item data-testid="show-labels-toggle-item" @action="setShowLabels">
      <template #list-item>
        <local-storage-sync
          :value="isShowingLabels"
          storage-key="gl-show-board-labels"
          @input="setShowLabels"
        />
        <gl-toggle
          :value="isShowingLabels"
          :label="$options.i18n.showLabels"
          :data-track-property="trackProperty"
          data-track-action="toggle"
          data-track-label="show_labels"
          label-position="left"
          aria-describedby="board-labels-toggle-text"
          data-testid="show-labels-toggle"
          class="board-dropdown-toggle gl-w-full gl-flex-row gl-justify-between"
        />
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item
      v-if="showEpicLaneOption"
      data-testid="epic-swimlanes-toggle-item"
      @action="onToggleSwimLanes"
    >
      <template #list-item>
        <toggle-epics-swimlanes :is-swimlanes-on="isSwimlanesOn" />
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
