/* eslint-disable */

import { ACTIVE_CLASS } from './constants';

const Keyboard = function () {
  var currentKey;
  var currentFocus;
  var isUpArrow = false;
  var isDownArrow = false;
  var removeHighlight = function removeHighlight(list) {
    var itemElements = Array.prototype.slice.call(
      list.list.querySelectorAll('li:not(.divider):not(.hidden)'),
      0,
    );
    var listItems = [];
    for (var i = 0; i < itemElements.length; i++) {
      var listItem = itemElements[i];
      listItem.classList.remove(ACTIVE_CLASS);

      if (listItem.style.display !== 'none') {
        listItems.push(listItem);
      }
    }
    return listItems;
  };

  var setMenuForArrows = function setMenuForArrows(list) {
    var listItems = removeHighlight(list);
    if (list.currentIndex > 0) {
      if (!listItems[list.currentIndex - 1]) {
        list.currentIndex = list.currentIndex - 1;
      }

      if (listItems[list.currentIndex - 1]) {
        var el = listItems[list.currentIndex - 1];
        var filterDropdownEl = el.closest('.filter-dropdown');
        el.classList.add(ACTIVE_CLASS);

        if (filterDropdownEl) {
          var filterDropdownBottom = filterDropdownEl.offsetHeight;
          var elOffsetTop = el.offsetTop - 30;

          if (elOffsetTop > filterDropdownBottom) {
            filterDropdownEl.scrollTop = elOffsetTop - filterDropdownBottom;
          }
        }
      }
    }
  };

  var mousedown = function mousedown(e) {
    var list = e.detail.hook.list;
    removeHighlight(list);
    list.show();
    list.currentIndex = 0;
    isUpArrow = false;
    isDownArrow = false;
  };
  var selectItem = function selectItem(list) {
    var listItems = removeHighlight(list);
    var currentItem = listItems[list.currentIndex - 1];
    var listEvent = new CustomEvent('click.dl', {
      detail: {
        list: list,
        selected: currentItem,
        data: currentItem.dataset,
      },
    });
    list.list.dispatchEvent(listEvent);
    list.hide();
  };

  var keydown = function keydown(e) {
    var typedOn = e.target;
    var list = e.detail.hook.list;
    var currentIndex = list.currentIndex;
    isUpArrow = false;
    isDownArrow = false;

    if (e.detail.which) {
      currentKey = e.detail.which;
      if (currentKey === 13) {
        selectItem(e.detail.hook.list);
        return;
      }
      if (currentKey === 38) {
        isUpArrow = true;
      }
      if (currentKey === 40) {
        isDownArrow = true;
      }
    } else if (e.detail.key) {
      currentKey = e.detail.key;
      if (currentKey === 'Enter') {
        selectItem(e.detail.hook.list);
        return;
      }
      if (currentKey === 'ArrowUp') {
        isUpArrow = true;
      }
      if (currentKey === 'ArrowDown') {
        isDownArrow = true;
      }
    }
    if (isUpArrow) {
      currentIndex--;
    }
    if (isDownArrow) {
      currentIndex++;
    }
    if (currentIndex < 0) {
      currentIndex = 0;
    }
    list.currentIndex = currentIndex;
    setMenuForArrows(e.detail.hook.list);
  };

  document.addEventListener('mousedown.dl', mousedown);
  document.addEventListener('keydown.dl', keydown);
};

export default Keyboard;
