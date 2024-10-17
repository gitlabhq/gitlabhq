<script>
import { GlModalDirective, GlTooltipDirective, GlIcon, GlButton } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { InternalEvents } from '~/tracking';
import {
  isNarrowScreen,
  isNarrowScreenAddListener,
  isNarrowScreenRemoveListener,
} from '~/lib/utils/css_utils';
import { SEARCH_MODAL_ID } from '../constants';
import SearchModal from './global_search.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  SEARCH_MODAL_ID,
  components: {
    GlIcon,
    SearchModal,
    GlButton,
  },
  i18n: {
    searchBtnText: __('Search or go to…'),
    searchKbdHelp: sprintf(
      s__('GlobalSearch|Type %{kbdOpen}/%{kbdClose} to search'),
      { kbdOpen: '<kbd>', kbdClose: '</kbd>' },
      false,
    ),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin(), trackingMixin],
  data() {
    return {
      searchTooltip: this.$options.i18n.searchKbdHelp,
      isNarrowScreen: false,
    };
  },
  mounted() {
    this.isNarrowScreen = isNarrowScreen();
    isNarrowScreenAddListener(this.handleNarrowScreenChange);
  },
  beforeDestroy() {
    isNarrowScreenRemoveListener(this.handleNarrowScreenChange);
  },
  methods: {
    handleNarrowScreenChange({ matches }) {
      this.isNarrowScreen = matches;
    },
    hideSearchTooltip() {
      this.searchTooltip = '';
    },
    showSearchTooltip() {
      this.searchTooltip = this.$options.i18n.searchKbdHelp;
    },
  },
};
</script>

<template>
  <div
    v-if="glFeatures.searchButtonTopRight"
    :class="{ 'border-0 gl-w-[300px] gl-rounded-base': !isNarrowScreen }"
  >
    <gl-button
      id="super-sidebar-search"
      v-gl-tooltip.bottom.html="searchTooltip"
      v-gl-modal="$options.SEARCH_MODAL_ID"
      :class="
        isNarrowScreen
          ? 'border-0 shadow-none bg-transparent'
          : 'user-bar-button gl-w-[300px] !gl-justify-start'
      "
      data-testid="super-sidebar-search-button"
      @click="trackEvent('click_search_button_to_activate_command_palette', { label: 'top_right' })"
    >
      <gl-icon name="search" />
      <span v-if="!isNarrowScreen">{{ $options.i18n.searchBtnText }}</span>
    </gl-button>
    <search-modal @shown="hideSearchTooltip" @hidden="showSearchTooltip" />
  </div>
</template>
