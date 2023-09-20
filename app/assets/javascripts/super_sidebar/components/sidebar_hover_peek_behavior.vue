<script>
import { getCssClassDimensions } from '~/lib/utils/css_utils';
import Tracking from '~/tracking';
import {
  JS_TOGGLE_EXPAND_CLASS,
  SUPER_SIDEBAR_PEEK_OPEN_DELAY,
  SUPER_SIDEBAR_PEEK_CLOSE_DELAY,
  SUPER_SIDEBAR_PEEK_STATE_CLOSED as STATE_CLOSED,
  SUPER_SIDEBAR_PEEK_STATE_WILL_OPEN as STATE_WILL_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_OPEN as STATE_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_WILL_CLOSE as STATE_WILL_CLOSE,
} from '../constants';

export default {
  name: 'SidebarHoverPeek',
  mixins: [Tracking.mixin()],
  props: {
    isMouseOverSidebar: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  created() {
    // Nothing needs to observe these properties, so they are not reactive.
    this.state = null;
    this.openTimer = null;
    this.closeTimer = null;
    this.xSidebarEdge = null;
    this.isMouseWithinSidebarArea = false;
  },
  async mounted() {
    await this.$nextTick();
    this.xSidebarEdge = getCssClassDimensions('super-sidebar').width;
    document.addEventListener('mousemove', this.onMouseMove);
    document.documentElement.addEventListener('mouseleave', this.onDocumentLeave);
    document
      .querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`)
      .addEventListener('mouseenter', this.onMouseEnter);
    document
      .querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`)
      .addEventListener('mouseleave', this.onMouseLeave);
    this.changeState(STATE_CLOSED);
  },
  beforeDestroy() {
    document.removeEventListener('mousemove', this.onMouseMove);
    document.documentElement.removeEventListener('mouseleave', this.onDocumentLeave);
    document
      .querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`)
      .removeEventListener('mouseenter', this.onMouseEnter);
    document
      .querySelector(`.${JS_TOGGLE_EXPAND_CLASS}`)
      .removeEventListener('mouseleave', this.onMouseLeave);
    this.clearTimers();
  },
  methods: {
    onMouseMove({ clientX }) {
      if (clientX < this.xSidebarEdge) {
        this.isMouseWithinSidebarArea = true;
      } else {
        this.isMouseWithinSidebarArea = false;
        if (!this.isMouseOverSidebar && this.state === STATE_OPEN) {
          this.willClose();
        }
      }
    },
    onDocumentLeave() {
      this.isMouseWithinSidebarArea = false;
      if (this.state === STATE_OPEN) {
        this.willClose();
      } else if (this.state === STATE_WILL_OPEN) {
        this.close();
      }
    },
    onMouseEnter() {
      clearTimeout(this.closeTimer);
      this.willOpen();
    },
    onMouseLeave() {
      clearTimeout(this.openTimer);
      if (this.isMouseWithinSidebarArea || this.isMouseOverSidebar) return;
      this.willClose();
    },
    willClose() {
      this.changeState(STATE_WILL_CLOSE);
      this.closeTimer = setTimeout(this.close, SUPER_SIDEBAR_PEEK_CLOSE_DELAY);
    },
    willOpen() {
      this.changeState(STATE_WILL_OPEN);
      this.openTimer = setTimeout(this.open, SUPER_SIDEBAR_PEEK_OPEN_DELAY);
    },
    open() {
      this.changeState(STATE_OPEN);
      this.clearTimers();
      this.track('nav_hover_peek', {
        label: 'nav_sidebar_toggle',
        property: 'nav_sidebar',
      });
    },
    close() {
      if (this.isMouseWithinSidebarArea) return;
      this.changeState(STATE_CLOSED);
      this.clearTimers();
    },
    clearTimers() {
      clearTimeout(this.closeTimer);
      clearTimeout(this.openTimer);
    },
    /**
     * Switches to the new state, and emits a change event.
     *
     * If the given state is the current state, do nothing.
     *
     * @param {string} state The state to transition to.
     */
    changeState(state) {
      if (this.state === state) return;
      this.state = state;
      this.$emit('change', state);
    },
  },
  render() {
    return null;
  },
};
</script>
