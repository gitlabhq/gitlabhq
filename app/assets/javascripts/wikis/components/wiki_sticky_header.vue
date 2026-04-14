<script>
import { GlButton, GlLink, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WikiMoreDropdown from './wiki_more_dropdown.vue';

export default {
  name: 'WikiStickyHeader',
  components: {
    GlButton,
    GlIcon,
    GlLink,
    WikiMoreDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    isStickyHeaderShowing: {
      type: Boolean,
      required: true,
    },
    pageHeading: {
      type: String,
      required: true,
    },
    showEditButton: {
      type: Boolean,
      required: true,
    },
    wikiPage: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['edit', 'toggle-subscribe'],
  computed: {
    subscribeIcon() {
      return this.wikiPage?.subscribed ? 'notifications' : 'notifications-off';
    },
    subscribeTooltip() {
      return this.wikiPage?.subscribed ? __('Notifications On') : __('Notifications Off');
    },
  },
};
</script>

<template>
  <div
    data-testid="wiki-sticky-header"
    class="gl-duration-200 gl-border-b gl-fixed gl-left-0 gl-right-0 gl-top-0 gl-z-3 gl-bg-default gl-py-2 gl-transition-all print:gl-hidden"
    :class="{
      '-gl-translate-y-full': !isStickyHeaderShowing,
      'gl-translate-y-0': isStickyHeaderShowing,
    }"
  >
    <div class="py-1 gl-mx-auto gl-flex gl-items-center gl-gap-3 gl-px-5 @xl/panel:gl-px-6">
      <gl-link
        href="#top"
        :class="['gl-ml-8 gl-mr-auto gl-block gl-truncate gl-pr-3 gl-font-bold gl-text-strong']"
        :title="pageHeading"
      >
        {{ pageHeading }}
      </gl-link>

      <gl-button
        v-if="showEditButton"
        category="secondary"
        class="gl-shrink-0"
        data-testid="wiki-sticky-edit-button"
        @click="$emit('edit')"
      >
        {{ __('Edit') }}
      </gl-button>

      <gl-button
        v-gl-tooltip.html
        category="secondary"
        class="btn-icon gl-shrink-0"
        :disabled="!wikiPage?.id"
        :title="subscribeTooltip"
        data-testid="wiki-sticky-subscribe-button"
        @click="$emit('toggle-subscribe')"
      >
        <gl-icon :name="subscribeIcon" :class="{ '!gl-text-status-info': wikiPage.subscribed }" />
      </gl-button>

      <wiki-more-dropdown
        class="gl-shrink-0"
        dropdown-testid="wiki-sticky-more-dropdown"
        delete-modal-id="delete-wiki-modal-sticky"
        clone-modal-id="clone-wiki-modal-sticky"
      />
    </div>
  </div>
</template>
