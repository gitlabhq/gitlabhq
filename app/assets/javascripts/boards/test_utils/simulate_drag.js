(function () {
	'use strict';

	function simulateEvent(el, type, options) {
		var event;
		if (!el) return;
		var ownerDocument = el.ownerDocument;

		options = options || {};

		if (/^mouse/.test(type)) {
			event = ownerDocument.createEvent('MouseEvents');
			event.initMouseEvent(type, true, true, ownerDocument.defaultView,
				options.button, options.screenX, options.screenY, options.clientX, options.clientY,
				options.ctrlKey, options.altKey, options.shiftKey, options.metaKey, options.button, el);
		} else {
			event = ownerDocument.createEvent('CustomEvent');

			event.initCustomEvent(type, true, true, ownerDocument.defaultView,
				options.button, options.screenX, options.screenY, options.clientX, options.clientY,
				options.ctrlKey, options.altKey, options.shiftKey, options.metaKey, options.button, el);

			event.dataTransfer = {
				data: {},

				setData: function (type, val) {
					this.data[type] = val;
				},

				getData: function (type) {
					return this.data[type];
				}
			};
		}

		if (el.dispatchEvent) {
			el.dispatchEvent(event);
		} else if (el.fireEvent) {
			el.fireEvent('on' + type, event);
		}

		return event;
	}

	function getTraget(target) {
		var el = typeof target.el === 'string' ? document.getElementById(target.el.substr(1)) : target.el;
		var children = el.children;

		return (
			children[target.index] ||
			children[target.index === 'first' ? 0 : -1] ||
			children[target.index === 'last' ? children.length - 1 : -1]
		);
	}

	function getRect(el) {
		var rect = el.getBoundingClientRect();
		var width = rect.right - rect.left;
		var height = rect.bottom - rect.top;

		return {
			x: rect.left,
			y: rect.top,
			cx: rect.left + width / 2,
			cy: rect.top + height / 2,
			w: width,
			h: height,
			hw: width / 2,
			wh: height / 2
		};
	}

	function simulateDrag(options, callback) {
		options.to.el = options.to.el || options.from.el;

		var fromEl = getTraget(options.from);
		var toEl = getTraget(options.to);
    var scrollable = options.scrollable;

		var fromRect = getRect(fromEl);
		var toRect = getRect(toEl);

		var startTime = new Date().getTime();
		var duration = options.duration || 1000;
		simulateEvent(fromEl, 'mousedown', {button: 0});
		options.ontap && options.ontap();

		requestAnimationFrame(function () {
			options.ondragstart && options.ondragstart();
		});

		requestAnimationFrame(function loop() {
			var progress = (new Date().getTime() - startTime) / duration;
			var x = (fromRect.cx + (toRect.cx - fromRect.cx) * progress) - scrollable.scrollLeft;
			var y = fromRect.cy + (toRect.cy - fromRect.cy) * progress;
			var overEl = fromEl.ownerDocument.elementFromPoint(x, y);

			simulateEvent(overEl, 'mousemove', {
				clientX: x,
				clientY: y
			});

			if (progress < 1) {
				requestAnimationFrame(loop);
			} else {
				options.ondragend && options.ondragend();
				simulateEvent(toEl, 'mouseup');
			}
		});

		return {
			target: fromEl,
			fromList: fromEl.parentNode,
			toList: toEl.parentNode
		};
	}


	// Export
	window.simulateEvent = simulateEvent;
	window.simulateDrag = simulateDrag;
})();
