<script>
import { GlModalDirective, GlIcon, GlButton, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
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
    GlSprintf,
  },
  i18n: {
    searchKbdHelp: s__('GlobalSearch|Search or go to… (or use the / keyboard shortcut)'),
    searchBtnText: s__('GlobalSearch|Search or go to… %{kbdStart}/%{kbdEnd}'),
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin(), trackingMixin],
  data() {
    return {
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
  },
};
</script>

<template>
  <div
    v-if="glFeatures.searchButtonTopRight"
    :class="{ 'border-0 gl-rounded-base': !isNarrowScreen }"
  >
    <gl-button
      id="super-sidebar-search"
      v-gl-modal="$options.SEARCH_MODAL_ID"
      class="gl-relative focus:!gl-focus"
      :title="$options.i18n.searchKbdHelp"
      :aria-label="$options.i18n.searchKbdHelp"
      :class="
        isNarrowScreen
          ? 'shadow-none bg-transparent gl-border gl-w-6 !gl-p-0'
          : 'user-bar-button gl-w-full !gl-justify-start !gl-pr-15'
      "
      data-testid="super-sidebar-search-button"
      @click="trackEvent('click_search_button_to_activate_command_palette', { label: 'top_right' })"
    >
      <gl-icon name="search" />
      <span v-if="!isNarrowScreen">
        <gl-sprintf :message="$options.i18n.searchBtnText">
          <template #kbd="{ content }">
            <span class="gl-absolute gl-right-4"
              ><kbd>{{ content }}</kbd></span
            >
          </template>
        </gl-sprintf>
      </span>
    </gl-button>
    <search-modal />
  </div>
</template>
