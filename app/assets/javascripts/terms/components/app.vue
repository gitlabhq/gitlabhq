<script>
import { GlButton, GlIntersectionObserver } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';

import { isLoggedIn } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import { trackTrialAcceptTerms } from 'ee_else_ce/google_tag_manager';
import { renderGFM } from '~/behaviors/markdown/render_gfm';

export default {
  name: 'TermsApp',
  i18n: {
    accept: __('Accept terms'),
    continue: __('Continue'),
    decline: __('Decline and sign out'),
  },
  flashElements: [],
  csrf,
  directives: {
    SafeHtml,
  },
  components: { GlButton, GlIntersectionObserver },
  inject: ['terms', 'permissions', 'paths'],
  data() {
    return {
      acceptDisabled: true,
      observer: new MutationObserver(() => {
        this.setScrollableViewportHeight();
      }),
    };
  },
  computed: {
    isLoggedIn,
  },
  mounted() {
    this.renderGFM();
    this.setScrollableViewportHeight();
    this.observer.observe(document.body, { childList: true, subtree: true });
  },
  beforeDestroy() {
    this.observer.disconnect();
  },
  methods: {
    renderGFM() {
      renderGFM(this.$refs.gfmContainer);
    },
    handleBottomReached() {
      this.acceptDisabled = false;
    },
    setScrollableViewportHeight() {
      // Reset `max-height` inline style
      this.$refs.scrollableViewport.style.maxHeight = '';

      const { scrollHeight, clientHeight } = document.documentElement;

      // Set `max-height` to 100vh minus all elements that are NOT the scrollable viewport (header, footer, alerts, etc)
      this.$refs.scrollableViewport.style.maxHeight = `calc(100vh - ${
        scrollHeight - clientHeight
      }px)`;
    },
    trackTrialAcceptTerms,
  },
};
</script>

<template>
  <div>
    <div class="gl-relative" data-testid="terms-content">
      <div
        class="terms-fade gl-pointer-events-none gl-absolute gl-bottom-0 gl-left-5 gl-right-5 gl-z-1 gl-h-11"
      ></div>
      <div
        ref="scrollableViewport"
        data-testid="scrollable-viewport"
        class="gl-h-screen gl-overflow-y-auto gl-p-7 gl-pb-11"
      >
        <div ref="gfmContainer" v-safe-html="terms"></div>
        <gl-intersection-observer @appear="handleBottomReached">
          <div></div>
        </gl-intersection-observer>
      </div>
    </div>
    <div v-if="isLoggedIn" class="gl-flex gl-justify-end gl-p-5">
      <form v-if="permissions.canDecline" method="post" :action="paths.decline">
        <gl-button type="submit">{{ $options.i18n.decline }}</gl-button>
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      </form>
      <form
        v-if="permissions.canAccept"
        class="gl-ml-3"
        method="post"
        :action="paths.accept"
        @submit="trackTrialAcceptTerms"
      >
        <gl-button
          type="submit"
          variant="confirm"
          :disabled="acceptDisabled"
          data-testid="accept-terms-button"
          >{{ $options.i18n.accept }}</gl-button
        >
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      </form>
      <gl-button v-else class="gl-ml-3" :href="paths.root" variant="confirm">{{
        $options.i18n.continue
      }}</gl-button>
    </div>
  </div>
</template>
