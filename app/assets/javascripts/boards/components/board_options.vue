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
    toggleEpicsSwimlanes() {
      this.$emit('toggleSwimlanes', !this.isSwimlanesOn);
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
          class="gl-flex-direction-row gl-justify-between gl-w-full"
        />
      </template>
    </gl-disclosure-dropdown-item>
    <gl-disclosure-dropdown-item
      v-if="showEpicLaneOption"
      data-testid="epic-swimlanes-toggle-item"
      @action="toggleEpicsSwimlanes"
    >
      <template #list-item>
        <toggle-epics-swimlanes :is-swimlanes-on="isSwimlanesOn" />
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
