function simulateEvent(el, type, options = {}) {
  let event;
  if (!el) return null;

  if (/^(pointer|mouse)/.test(type)) {
    event = el.ownerDocument.createEvent('MouseEvent');
    event.initMouseEvent(
      type,
      true,
      true,
      el.ownerDocument.defaultView,
      options.button,
      options.screenX,
      options.screenY,
      options.clientX,
      options.clientY,
      options.ctrlKey,
      options.altKey,
      options.shiftKey,
      options.metaKey,
      options.button,
      el,
    );
  } else {
    event = el.ownerDocument.createEvent('CustomEvent');

    event.initCustomEvent(
      type,
      true,
      true,
      el.ownerDocument.defaultView,
      options.button,
      options.screenX,
      options.screenY,
      options.clientX,
      options.clientY,
      options.ctrlKey,
      options.altKey,
      options.shiftKey,
      options.metaKey,
      options.button,
      el,
    );

    event.dataTransfer = {
      data: {},

      setData(key, val) {
        this.data[key] = val;
      },

      getData(key) {
        return this.data[key];
      },
    };
  }

  if (el.dispatchEvent) {
    el.dispatchEvent(event);
  } else if (el.fireEvent) {
    el.fireEvent(`on${type}`, event);
  }

  return event;
}

function isLast(target) {
  const el =
    typeof target.el === 'string' ? document.getElementById(target.el.substr(1)) : target.el;
  const { children } = el;

  return children.length - 1 === target.index;
}

function getTarget(target) {
  const el =
    typeof target.el === 'string' ? document.getElementById(target.el.substr(1)) : target.el;
  const { children } = el;

  return (
    children[target.index] ||
    children[target.index === 'first' ? 0 : -1] ||
    children[target.index === 'last' ? children.length - 1 : -1] ||
    el
  );
}

function getRect(el) {
  const rect = el.getBoundingClientRect();
  const width = rect.right - rect.left;
  const height = rect.bottom - rect.top + 10;

  return {
    x: rect.left,
    y: rect.top,
    cx: rect.left + width / 2,
    cy: rect.top + height / 2,
    w: width,
    h: height,
    hw: width / 2,
    wh: height / 2,
  };
}

export default function simulateDrag(options) {
  const { to, from } = options;
  to.el = to.el || from.el;

  const fromEl = getTarget(from);
  const toEl = getTarget(to);
  const firstEl = getTarget({
    el: to.el,
    index: 'first',
  });
  const lastEl = getTarget({
    el: options.to.el,
    index: 'last',
  });

  const fromRect = getRect(fromEl);
  const toRect = getRect(toEl);
  const firstRect = getRect(firstEl);
  const lastRect = getRect(lastEl);

  const duration = options.duration || 1000;

  simulateEvent(fromEl, 'pointerdown', {
    button: 0,
    clientX: fromRect.cx,
    clientY: fromRect.cy,
  });

  if (options.ontap) options.ontap();
  window.SIMULATE_DRAG_ACTIVE = 1;

  if (options.to.index === 0) {
    toRect.cy = firstRect.y;
  } else if (isLast(options.to)) {
    toRect.cy = lastRect.y + lastRect.h + 50;
  }

  let startTime;

  // Called within dragFn when the drag should finish
  const finishFn = () => {
    if (options.ondragend) options.ondragend();

    if (options.performDrop) {
      simulateEvent(toEl, 'mouseup');
    }

    window.SIMULATE_DRAG_ACTIVE = 0;
  };

  const dragFn = (timestamp) => {
    if (!startTime) {
      startTime = timestamp;
    }

    const elapsed = timestamp - startTime;

    // Make sure that progress maxes at 1
    const progress = Math.min(elapsed / duration, 1);
    const x = fromRect.cx + (toRect.cx - fromRect.cx) * progress;
    const y = fromRect.cy + (toRect.cy - fromRect.cy + options.extraHeight) * progress;
    const overEl = fromEl.ownerDocument.elementFromPoint(x, y);

    simulateEvent(overEl, 'pointermove', {
      clientX: x,
      clientY: y,
    });

    if (progress >= 1) {
      // finish on next frame, so we can pause in the correct position for a frame
      requestAnimationFrame(finishFn);
    } else {
      requestAnimationFrame(dragFn);
    }
  };

  // Start the drag animation
  requestAnimationFrame(dragFn);

  return {
    target: fromEl,
    fromList: fromEl.parentNode,
    toList: toEl.parentNode,
  };
}
