import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import {
  SUPER_SIDEBAR_PEEK_OPEN_DELAY,
  SUPER_SIDEBAR_PEEK_CLOSE_DELAY,
  JS_TOGGLE_EXPAND_CLASS,
  SUPER_SIDEBAR_PEEK_STATE_CLOSED as STATE_CLOSED,
  SUPER_SIDEBAR_PEEK_STATE_WILL_OPEN as STATE_WILL_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_OPEN as STATE_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_WILL_CLOSE as STATE_WILL_CLOSE,
} from '~/super_sidebar/constants';
import SidebarHoverPeek from '~/super_sidebar/components/sidebar_hover_peek_behavior.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { moveMouse, mouseEnter, mouseLeave, moveMouseOutOfDocument } from '../mocks';

// This is measured at runtime in the browser, but statically defined here
// since Jest does not do layout/styling.
const X_SIDEBAR_EDGE = 10;

jest.mock('~/lib/utils/css_utils', () => ({
  getCssClassDimensions: () => ({ width: X_SIDEBAR_EDGE }),
}));

describe('SidebarHoverPeek component', () => {
  let wrapper;
  let toggle;
  let trackingSpy = null;

  const createComponent = (props = { isMouseOverSidebar: false }) => {
    wrapper = mount(SidebarHoverPeek, {
      propsData: props,
    });

    return nextTick();
  };

  const lastNChangeEvents = (n = 1) => wrapper.emitted('change').slice(-n).flat();

  /**
   * Simulates destroying the component. This is unusual! It's needed for tests
   * that verify the clean up behavior of the component.
   *
   * Normally `wrapper.destroy()` would be the correct way to do this, but:
   *
   * - VTU@2 removes emitted event history on unmount/destroy:
   *   https://github.com/vuejs/test-utils/blob/3207debb67591d63932f6a4228e2d21d7525450c/src/vueWrapper.ts#L271-L272
   * - Attaching listeners via a harness/dummy component isn't sufficient, as
   *   the listeners are removed anyway on destroy, so the tests would pass
   *   whether or not the clean up behavior actually happens.
   * - Spying on `EventTarget#removeEventListener` is another possible
   *   approach, but that's brittle. Selectors/event names could change.
   */
  const simulateDestroy = () => SidebarHoverPeek.beforeDestroy.call(wrapper.vm);

  beforeEach(() => {
    toggle = document.createElement('button');
    toggle.classList.add(JS_TOGGLE_EXPAND_CLASS);
    document.body.appendChild(toggle);
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
    // We destroy the wrapper ourselves as that needs to happen before the toggle is removed.
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
    toggle?.remove();
  });

  it('begins in the closed state', async () => {
    await createComponent();

    expect(lastNChangeEvents(Infinity)).toEqual([STATE_CLOSED]);
  });

  describe('when mouse enters the toggle', () => {
    beforeEach(async () => {
      await createComponent();
      mouseEnter(toggle);
    });

    it('does not emit duplicate events in a region', () => {
      mouseEnter(toggle);

      expect(lastNChangeEvents(Infinity)).toEqual([STATE_CLOSED, STATE_WILL_OPEN]);
    });

    it('transitions to will-open when hovering the toggle', () => {
      expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);
    });

    describe('when transitioning away from the will-open state', () => {
      beforeEach(() => {
        jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_OPEN_DELAY - 1);
      });

      it('transitions to open after delay', () => {
        expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);

        jest.advanceTimersByTime(1);

        expect(lastNChangeEvents(2)).toEqual([STATE_WILL_OPEN, STATE_OPEN]);
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'nav_hover_peek', {
          label: 'nav_sidebar_toggle',
          property: 'nav_sidebar',
        });
      });

      it('cancels transition to open if mouse out of toggle', () => {
        mouseLeave(toggle);
        jest.runOnlyPendingTimers();

        expect(lastNChangeEvents(3)).toEqual([STATE_WILL_OPEN, STATE_WILL_CLOSE, STATE_CLOSED]);
      });

      it('transitions to closed if cursor leaves document', () => {
        moveMouseOutOfDocument();

        expect(lastNChangeEvents(2)).toEqual([STATE_WILL_OPEN, STATE_CLOSED]);
      });
    });

    describe('when transitioning away from the will-close state', () => {
      beforeEach(() => {
        jest.runOnlyPendingTimers();
        moveMouse(X_SIDEBAR_EDGE);
        jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_CLOSE_DELAY - 1);
      });

      it('transitions to closed after delay', () => {
        expect(lastNChangeEvents(1)).toEqual([STATE_WILL_CLOSE]);

        jest.advanceTimersByTime(1);

        expect(lastNChangeEvents(2)).toEqual([STATE_WILL_CLOSE, STATE_CLOSED]);
      });

      it('cancels transition to close if mouse moves back to toggle', () => {
        expect(lastNChangeEvents(1)).toEqual([STATE_WILL_CLOSE]);

        mouseEnter(toggle);
        jest.runOnlyPendingTimers();

        expect(lastNChangeEvents(4)).toEqual([
          STATE_OPEN,
          STATE_WILL_CLOSE,
          STATE_WILL_OPEN,
          STATE_OPEN,
        ]);
      });
    });

    describe('when transitioning away from the open state', () => {
      beforeEach(() => {
        jest.runOnlyPendingTimers();
      });

      it('transitions to will-close if mouse out of sidebar region', () => {
        expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);

        moveMouse(X_SIDEBAR_EDGE);

        expect(lastNChangeEvents(2)).toEqual([STATE_OPEN, STATE_WILL_CLOSE]);
      });

      it('transitions to will-close if cursor leaves document', () => {
        moveMouseOutOfDocument();

        expect(lastNChangeEvents(2)).toEqual([STATE_OPEN, STATE_WILL_CLOSE]);
      });
    });

    it('cleans up its mouseleave listener before destroy', () => {
      jest.runOnlyPendingTimers();

      expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);

      simulateDestroy();
      mouseLeave(toggle);

      expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);
    });

    it('cleans up its timers before destroy', () => {
      simulateDestroy();
      jest.runOnlyPendingTimers();

      expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);
    });

    it('cleans up document mouseleave listener before destroy', () => {
      mouseEnter(toggle);

      simulateDestroy();

      moveMouseOutOfDocument();

      expect(lastNChangeEvents(1)).not.toEqual([STATE_CLOSED]);
    });
  });

  describe('when mouse is over sidebar child element', () => {
    beforeEach(async () => {
      await createComponent({ isMouseOverSidebar: true });
    });

    it('does not transition to will-close or closed when mouse is over sidebar child element', () => {
      mouseEnter(toggle);
      jest.runOnlyPendingTimers();
      mouseLeave(toggle);

      expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);
    });
  });

  it('cleans up its mouseenter listener before destroy', async () => {
    await createComponent();

    mouseLeave(toggle);
    jest.runOnlyPendingTimers();

    expect(lastNChangeEvents(1)).toEqual([STATE_CLOSED]);

    simulateDestroy();
    mouseEnter(toggle);

    expect(lastNChangeEvents(1)).toEqual([STATE_CLOSED]);
  });
});
