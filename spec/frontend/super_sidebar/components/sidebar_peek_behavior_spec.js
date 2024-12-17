import { mount } from '@vue/test-utils';
import {
  SUPER_SIDEBAR_PEEK_OPEN_DELAY,
  SUPER_SIDEBAR_PEEK_CLOSE_DELAY,
  SUPER_SIDEBAR_PEEK_STATE_CLOSED as STATE_CLOSED,
  SUPER_SIDEBAR_PEEK_STATE_WILL_OPEN as STATE_WILL_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_OPEN as STATE_OPEN,
  SUPER_SIDEBAR_PEEK_STATE_WILL_CLOSE as STATE_WILL_CLOSE,
} from '~/super_sidebar/constants';
import SidebarPeek from '~/super_sidebar/components/sidebar_peek_behavior.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { moveMouse, moveMouseOutOfDocument } from '../mocks';

// These are measured at runtime in the browser, but statically defined here
// since Jest does not do layout/styling.
const X_NEAR_WINDOW_EDGE = 5;
const X_SIDEBAR_EDGE = 10;
const X_AWAY_FROM_SIDEBAR = 20;

jest.mock('~/lib/utils/css_utils', () => ({
  getCssClassDimensions: (className) => {
    if (className === 'gl-w-3') {
      return { width: X_NEAR_WINDOW_EDGE };
    }

    if (className === 'super-sidebar') {
      return { width: X_SIDEBAR_EDGE };
    }

    throw new Error(`No mock for CSS class ${className}`);
  },
}));

describe('SidebarPeek component', () => {
  let wrapper;
  let trackingSpy = null;

  const createComponent = (props = { isMouseOverSidebar: false }) => {
    wrapper = mount(SidebarPeek, {
      propsData: props,
    });
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
  const simulateDestroy = () => SidebarPeek.beforeDestroy.call(wrapper.vm);

  beforeEach(() => {
    createComponent();
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
  });

  it('begins in the closed state', () => {
    expect(lastNChangeEvents(Infinity)).toEqual([STATE_CLOSED]);
  });

  it('does not emit duplicate events in a region', () => {
    moveMouse(0);
    moveMouse(1);
    moveMouse(2);

    expect(lastNChangeEvents(Infinity)).toEqual([STATE_CLOSED, STATE_WILL_OPEN]);
  });

  it('transitions to will-open when in peek region', () => {
    moveMouse(X_NEAR_WINDOW_EDGE);

    expect(lastNChangeEvents(1)).toEqual([STATE_CLOSED]);

    moveMouse(X_NEAR_WINDOW_EDGE - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);
  });

  it('transitions will-open -> open after delay', () => {
    moveMouse(0);
    jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_OPEN_DELAY - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);

    jest.advanceTimersByTime(1);

    expect(lastNChangeEvents(2)).toEqual([STATE_WILL_OPEN, STATE_OPEN]);

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'nav_peek', {
      label: 'nav_hover',
      property: 'nav_sidebar',
    });
  });

  it('cancels transition will-open -> open if mouse out of peek region', () => {
    moveMouse(0);
    jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_OPEN_DELAY - 1);

    moveMouse(X_NEAR_WINDOW_EDGE);

    jest.runOnlyPendingTimers();

    expect(lastNChangeEvents(3)).toEqual([STATE_CLOSED, STATE_WILL_OPEN, STATE_CLOSED]);
  });

  it('transitions open -> will-close if mouse out of sidebar region', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_SIDEBAR_EDGE - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);

    moveMouse(X_SIDEBAR_EDGE);

    expect(lastNChangeEvents(2)).toEqual([STATE_OPEN, STATE_WILL_CLOSE]);
  });

  it('transitions will-close -> closed after delay', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_SIDEBAR_EDGE);
    jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_CLOSE_DELAY - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_CLOSE]);

    jest.advanceTimersByTime(1);

    expect(lastNChangeEvents(2)).toEqual([STATE_WILL_CLOSE, STATE_CLOSED]);
  });

  it('cancels transition will-close -> close if mouse move in sidebar region', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_SIDEBAR_EDGE);
    jest.advanceTimersByTime(SUPER_SIDEBAR_PEEK_CLOSE_DELAY - 1);

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_CLOSE]);

    moveMouse(X_SIDEBAR_EDGE - 1);
    jest.runOnlyPendingTimers();

    expect(lastNChangeEvents(3)).toEqual([STATE_OPEN, STATE_WILL_CLOSE, STATE_OPEN]);
  });

  it('immediately transitions open -> closed if mouse moves far away', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_AWAY_FROM_SIDEBAR);

    expect(lastNChangeEvents(2)).toEqual([STATE_OPEN, STATE_CLOSED]);
  });

  it('does not transition to will-close or closed when mouse is over sidebar child element', () => {
    createComponent({ isMouseOverSidebar: true });
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_SIDEBAR_EDGE);
    moveMouse(X_AWAY_FROM_SIDEBAR);

    expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);
  });

  it('immediately transitions will-close -> closed if mouse moves far away', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    moveMouse(X_AWAY_FROM_SIDEBAR - 1);
    moveMouse(X_AWAY_FROM_SIDEBAR);

    expect(lastNChangeEvents(2)).toEqual([STATE_WILL_CLOSE, STATE_CLOSED]);
  });

  it('cleans up its mousemove listener before destroy', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();

    simulateDestroy();
    moveMouse(X_AWAY_FROM_SIDEBAR);

    expect(lastNChangeEvents(1)).toEqual([STATE_OPEN]);
  });

  it('cleans up its timers before destroy', () => {
    moveMouse(0);

    simulateDestroy();
    jest.runOnlyPendingTimers();

    expect(lastNChangeEvents(1)).toEqual([STATE_WILL_OPEN]);
  });

  it('transitions will-open -> closed if cursor leaves document', () => {
    moveMouse(0);
    moveMouseOutOfDocument();

    expect(lastNChangeEvents(2)).toEqual([STATE_WILL_OPEN, STATE_CLOSED]);
  });

  it('transitions open -> will-close if cursor leaves document', () => {
    moveMouse(0);
    jest.runOnlyPendingTimers();
    moveMouseOutOfDocument();

    expect(lastNChangeEvents(2)).toEqual([STATE_OPEN, STATE_WILL_CLOSE]);
  });

  it('cleans up document mouseleave listener before destroy', () => {
    moveMouse(0);

    simulateDestroy();

    moveMouseOutOfDocument();

    expect(lastNChangeEvents(1)).not.toEqual([STATE_CLOSED]);
  });
});
