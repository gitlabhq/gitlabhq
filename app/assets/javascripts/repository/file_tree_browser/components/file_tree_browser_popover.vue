<script>
import { GlBadge, GlPopover } from '@gitlab/ui';

const SHOW_DELAY = 500;
const DISMISS_TIMEOUT = 6000;

export default {
  name: 'FileTreeBrowserPopover',
  components: { GlBadge, GlPopover },
  props: {
    targetElement: {
      type: HTMLElement,
      required: true,
    },
  },
  emits: ['dismiss'],
  data() {
    return {
      show: false,
    };
  },
  mounted() {
    this.initializePopover();
  },
  beforeDestroy() {
    if (this.popoverShowTimeout) {
      clearTimeout(this.popoverShowTimeout);
    }
    if (this.popoverDismissTimeout) {
      clearTimeout(this.popoverDismissTimeout);
    }
    this.removeTargetListeners();
  },
  methods: {
    initializePopover() {
      this.popoverShowTimeout = setTimeout(() => {
        this.show = true;
      }, SHOW_DELAY);

      this.attachTargetListeners();

      this.popoverDismissTimeout = setTimeout(() => {
        this.show = false;
      }, DISMISS_TIMEOUT);
    },
    attachTargetListeners() {
      if (this.targetElement) {
        this.removeTargetListeners();

        this.onTargetHoverOrFocus = () => {
          this.show = false;
        };
        this.targetElement.addEventListener('mouseenter', this.onTargetHoverOrFocus);
        this.targetElement.addEventListener('focus', this.onTargetHoverOrFocus);
      }
    },
    removeTargetListeners() {
      if (this.targetElement && this.onTargetHoverOrFocus) {
        this.targetElement.removeEventListener('mouseenter', this.onTargetHoverOrFocus);
        this.targetElement.removeEventListener('focus', this.onTargetHoverOrFocus);
      }
    },
  },
};
</script>

<template>
  <gl-popover
    :show="show"
    :show-close-button="true"
    placement="bottom"
    boundary="viewport"
    :target="targetElement"
    triggers="manual"
    @hidden="$emit('dismiss')"
  >
    <template #title>
      <div class="gl-flex gl-items-center gl-justify-between gl-gap-3">
        {{ __('File tree navigation') }}
        <gl-badge variant="info" size="small">
          {{ __('New') }}
        </gl-badge>
      </div>
    </template>
    <template #default>
      <p class="gl-mb-0">
        {{ __('Browse your repository files and folders with the tree view sidebar.') }}
      </p>
    </template>
  </gl-popover>
</template>
