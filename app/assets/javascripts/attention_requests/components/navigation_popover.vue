<script>
import { GlPopover, GlSprintf, GlButton, GlLink, GlIcon } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  components: {
    GlPopover,
    GlSprintf,
    GlButton,
    GlLink,
    GlIcon,
    UserCalloutDismisser,
  },
  inject: {
    message: {
      default: '',
    },
    observerElSelector: {
      default: '',
    },
    observerElToggledClass: {
      default: '',
    },
    featureName: {
      default: '',
    },
    popoverTarget: {
      default: '',
    },
    showAttentionIcon: {
      default: false,
    },
    delay: {
      default: 0,
    },
    popoverCssClass: {
      default: '',
    },
  },
  data() {
    return {
      showPopover: false,
      popoverPlacement: this.popoverPosition(),
    };
  },
  mounted() {
    this.observeEl = document.querySelector(this.observerElSelector);
    this.observer = new MutationObserver(this.callback);
    this.observer.observe(this.observeEl, {
      attributes: true,
    });
    this.callback();

    window.addEventListener('resize', () => {
      this.popoverPlacement = this.popoverPosition();
    });
  },
  beforeDestroy() {
    this.observer.disconnect();
  },
  methods: {
    callback() {
      if (this.showPopover) {
        this.$root.$emit('bv::hide::popover');
      }

      setTimeout(() => this.toggleShowPopover(), this.delay);
    },
    toggleShowPopover() {
      this.showPopover = this.observeEl.classList.contains(this.observerElToggledClass);
    },
    getPopoverTarget() {
      return document.querySelector(this.popoverTarget);
    },
    popoverPosition() {
      if (bp.isDesktop()) {
        return 'left';
      }

      return 'bottom';
    },
  },
  docsPage: helpPagePath('development/code_review.html'),
};
</script>

<template>
  <user-callout-dismisser :feature-name="featureName">
    <template #default="{ shouldShowCallout, dismiss }">
      <gl-popover
        v-if="shouldShowCallout"
        :show-close-button="false"
        :target="() => getPopoverTarget()"
        :show="showPopover"
        :delay="0"
        triggers="manual"
        :placement="popoverPlacement"
        boundary="window"
        no-fade
        :css-classes="[popoverCssClass]"
      >
        <p v-for="(m, index) in message" :key="index" class="gl-mb-5">
          <gl-sprintf :message="m">
            <template #strong="{ content }">
              <strong><gl-icon v-if="showAttentionIcon" name="attention" /> {{ content }}</strong>
            </template>
          </gl-sprintf>
        </p>
        <div class="gl-display-flex gl-align-items-center">
          <gl-button size="small" variant="confirm" class="gl-mr-5" @click.prevent.stop="dismiss">
            {{ __('Got it!') }}
          </gl-button>
          <gl-link :href="$options.docsPage" target="_blank">{{ __('Learn more') }}</gl-link>
        </div>
      </gl-popover>
    </template>
  </user-callout-dismisser>
</template>
