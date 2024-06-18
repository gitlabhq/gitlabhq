<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { ALL_GITLAB } from '~/vue_shared/global_search/constants';
import {
  EVENT_CLICK_ISSUES_ASSIGNED_TO_ME_IN_COMMAND_PALETTE,
  EVENT_CLICK_ISSUES_I_CREATED_IN_COMMAND_PALETTE,
  EVENT_CLICK_MERGE_REQUESTS_ASSIGNED_TO_ME_IN_COMMAND_PALETTE,
  EVENT_CLICK_MERGE_REQUESTS_THAT_IM_A_REVIEWER_IN_COMMAND_PALETTE,
  EVENT_CLICK_MERGE_REQUESTS_I_CREATED_IN_COMMAND_PALETTE,
} from '~/super_sidebar/components/global_search/tracking_constants';
import { OVERLAY_GOTO } from '~/super_sidebar/components/global_search/command_palette/constants';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'DefaultIssuables',
  i18n: {
    ALL_GITLAB,
    OVERLAY_GOTO,
    ISSUES_ASSIGNED_TO_ME_TITLE: s__('GlobalSearch|Issues assigned to me'),
    ISSUES_I_HAVE_CREATED_TITLE: s__("GlobalSearch|Issues I've created"),
    MERGE_REQUESTS_THAT_I_AM_A_REVIEWER: s__("GlobalSearch|Merge requests that I'm a reviewer"),
    MERGE_REQUESTS_I_HAVE_CREATED_TITLE: s__("GlobalSearch|Merge requests I've created"),
    MERGE_REQUESTS_ASSIGNED_TO_ME_TITLE: s__('GlobalSearch|Merge requests assigned to me'),
  },
  components: {
    GlDisclosureDropdownGroup,
    SearchResultHoverLayover,
  },
  mixins: [trackingMixin],
  computed: {
    ...mapState(['searchContext']),
    ...mapGetters(['defaultSearchOptions']),
    currentContextName() {
      return (
        this.searchContext?.project?.name ||
        this.searchContext?.group?.name ||
        this.$options.i18n.ALL_GITLAB
      );
    },
    shouldRender() {
      return this.group.items.length > 0;
    },
    group() {
      return {
        name: this.currentContextName,
        items: this.defaultSearchOptions?.map((item) => ({
          ...item,
          extraAttrs: {
            class: 'show-hover-layover',
          },
        })),
      };
    },
  },
  created() {
    if (!this.shouldRender) {
      this.$emit('nothing-to-render');
    }
  },
  methods: {
    trackingTypes({ text }) {
      switch (text) {
        case this.$options.i18n.ISSUES_ASSIGNED_TO_ME_TITLE: {
          this.trackEvent(EVENT_CLICK_ISSUES_ASSIGNED_TO_ME_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.ISSUES_I_HAVE_CREATED_TITLE: {
          this.trackEvent(EVENT_CLICK_ISSUES_I_CREATED_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.MERGE_REQUESTS_ASSIGNED_TO_ME_TITLE: {
          this.trackEvent(EVENT_CLICK_MERGE_REQUESTS_ASSIGNED_TO_ME_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.MERGE_REQUESTS_THAT_I_AM_A_REVIEWER: {
          this.trackEvent(EVENT_CLICK_MERGE_REQUESTS_THAT_IM_A_REVIEWER_IN_COMMAND_PALETTE);
          break;
        }
        case this.$options.i18n.MERGE_REQUESTS_I_HAVE_CREATED_TITLE: {
          this.trackEvent(EVENT_CLICK_MERGE_REQUESTS_I_CREATED_IN_COMMAND_PALETTE);
          break;
        }

        default: {
          break;
        }
      }
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group
    v-if="shouldRender"
    v-bind="$attrs"
    :group="group"
    @action="trackingTypes"
  >
    <template #list-item="{ item }">
      <search-result-hover-layover :text-message="$options.i18n.OVERLAY_GOTO">
        <span>{{ item.text }}</span>
      </search-result-hover-layover>
    </template>
  </gl-disclosure-dropdown-group>
</template>
