<script>
import { GlDisclosureDropdownGroup } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapGetters } from 'vuex';
import { InternalEvents } from '~/tracking';
import { ALL_GITLAB } from '~/vue_shared/global_search/constants';
import {
  OVERLAY_GOTO,
  ISSUES_ASSIGNED_TO_ME_TITLE,
  ISSUES_I_HAVE_CREATED_TITLE,
  MERGE_REQUESTS_THAT_I_AM_A_REVIEWER,
  MERGE_REQUESTS_I_HAVE_CREATED_TITLE,
  MERGE_REQUESTS_ASSIGNED_TO_ME_TITLE,
} from '~/super_sidebar/components/global_search/command_palette/constants';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';

const trackingMixin = InternalEvents.mixin();

export default {
  name: 'DefaultIssuables',
  i18n: {
    ALL_GITLAB,
    OVERLAY_GOTO,
    ISSUES_ASSIGNED_TO_ME_TITLE,
    ISSUES_I_HAVE_CREATED_TITLE,
    MERGE_REQUESTS_THAT_I_AM_A_REVIEWER,
    MERGE_REQUESTS_I_HAVE_CREATED_TITLE,
    MERGE_REQUESTS_ASSIGNED_TO_ME_TITLE,
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
          this.trackEvent('click_issues_assigned_to_me_in_command_palette');
          break;
        }
        case this.$options.i18n.ISSUES_I_HAVE_CREATED_TITLE: {
          this.trackEvent('click_issues_i_created_in_command_palette');
          break;
        }
        case this.$options.i18n.MERGE_REQUESTS_ASSIGNED_TO_ME_TITLE: {
          this.trackEvent('click_merge_requests_assigned_to_me_in_command_palette');
          break;
        }
        case this.$options.i18n.MERGE_REQUESTS_THAT_I_AM_A_REVIEWER: {
          this.trackEvent('click_merge_requests_that_im_a_reviewer_in_command_palette');
          break;
        }
        case this.$options.i18n.MERGE_REQUESTS_I_HAVE_CREATED_TITLE: {
          this.trackEvent('click_merge_requests_i_created_in_command_palette');
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
