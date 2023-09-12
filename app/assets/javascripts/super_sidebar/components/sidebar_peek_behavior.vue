<script>
import { getCssClassDimensions } from '~/lib/utils/css_utils';
import Tracking from '~/tracking';
import {
  SUPER_SIDEBAR_PEEK_OPEN_DELAY,
  SUPER_SIDEBAR_PEEK_CLOSE_DELAY,
  SUPER_SIDEBAR_PEEK_STATE_CLOSED as STATE_CLOSED,
  SUPER_SIDEBAR_PEEK_STATE_WILL_OPEN as STATE_WILL_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_OPEN as STATE_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_WILL_CLOSE as STATE_WILL_CLOSE,
} from '../constants';

export default {
  name: 'SidebarPeek',
  mixins: [Tracking.mixin()],
  props: {
    isMouseOverSidebar: {
      type: Boolean,
      required: true,
    },
  },
  created() {
    // Nothing needs to observe these properties, so they are not reactive.
    this.state = null;
    this.openTimer = null;
    this.closeTimer = null;
    this.xNearWindowEdge = null;
    this.xSidebarEdge = null;
    this.xAwayFromSidebar = null;
  },
  mounted() {
    this.xNearWindowEdge = getCssClassDimensions('gl-w-3').width;
    this.xSidebarEdge = getCssClassDimensions('super-sidebar').width;
    this.xAwayFromSidebar = 2 * this.xSidebarEdge;
    document.addEventListener('mousemove', this.onMouseMove);
    document.documentElement.addEventListener('mouseleave', this.onDocumentLeave);
    this.changeState(STATE_CLOSED);
  },
  beforeDestroy() {
    document.removeEventListener('mousemove', this.onMouseMove);
    document.documentElement.removeEventListener('mouseleave', this.onDocumentLeave);
    this.clearTimers();
  },
  methods: {
    /**
     * Callback for document-wide mousemove events.
     *
     * Since mousemove events can fire frequently, it's important for this to
     * do as little work as possible.
     *
     * When mousemove events fire within one of the defined regions, this ends
     * up being a no-op. Only when the cursor moves from one region to another
     * does this do any work: it sets a non-reactive instance property, maybe
     * cancels/starts timers, and emits an event.
     *
     * @params {MouseEvent} event
     */
    onMouseMove({ clientX }) {
      if (this.state === STATE_CLOSED) {
        if (clientX < this.xNearWindowEdge) {
          this.willOpen();
        }
      } else if (this.state === STATE_WILL_OPEN) {
        if (clientX >= this.xNearWindowEdge) {
          this.close();
        }
      } else if (this.state === STATE_OPEN) {
        // Do not close the sidebar if it or one of its child elements still
        // has mouseover. This allows to move the mouse from the sidebar to
        // one of its flyout menus.
        if (this.isMouseOverSidebar) return;

        if (clientX >= this.xAwayFromSidebar) {
          this.close();
        } else if (clientX >= this.xSidebarEdge) {
          this.willClose();
        }
      } else if (this.state === STATE_WILL_CLOSE) {
        if (clientX >= this.xAwayFromSidebar) {
          this.close();
        } else if (clientX < this.xSidebarEdge) {
          this.open();
        }
      }
    },
    onDocumentLeave() {
      if (this.state === STATE_OPEN) {
        this.willClose();
      } else if (this.state === STATE_WILL_OPEN) {
        this.close();
      }
    },
    willClose() {
      if (this.changeState(STATE_WILL_CLOSE)) {
        this.closeTimer = setTimeout(this.close, SUPER_SIDEBAR_PEEK_CLOSE_DELAY);
      }
    },
    willOpen() {
      if (this.changeState(STATE_WILL_OPEN)) {
        this.openTimer = setTimeout(this.open, SUPER_SIDEBAR_PEEK_OPEN_DELAY);
      }
    },
    open() {
      if (this.changeState(STATE_OPEN)) {
        this.clearTimers();
        this.track('nav_peek', {
          label: 'nav_hover',
          property: 'nav_sidebar',
        });
      }
    },
    close() {
      if (this.changeState(STATE_CLOSED)) {
        this.clearTimers();
      }
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
     * @returns {boolean} True if the state changed, false otherwise.
     */
    changeState(state) {
      if (this.state === state) return false;

      this.state = state;
      this.$emit('change', state);
      return true;
    },
  },
  render() {
    return null;
  },
};
</script>
