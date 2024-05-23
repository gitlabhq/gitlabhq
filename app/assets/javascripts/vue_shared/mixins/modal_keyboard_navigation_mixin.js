import { clamp } from 'lodash';
import {
  ARROW_DOWN_KEY,
  ARROW_UP_KEY,
  END_KEY,
  HOME_KEY,
  ESC_KEY,
  NUMPAD_ENTER_KEY,
} from '~/lib/utils/keys';

export default {
  methods: {
    getFocusableOptions() {
      return Array.from(this.$refs.resultsList?.querySelectorAll('.gl-new-dropdown-item') || []);
    },
    onKeydown(event) {
      const { code, target } = event;

      let stop = true;

      const elements = this.getFocusableOptions();
      if (elements.length < 1) return;

      const isSearchInput = target.matches('input[role="searchbox"]');

      if (code === HOME_KEY) {
        if (isSearchInput) return;

        this.focusItem(0, elements);
      } else if (code === END_KEY) {
        if (isSearchInput) return;

        this.focusItem(elements.length - 1, elements);
      } else if (code === ARROW_UP_KEY) {
        if (isSearchInput) return;

        if (elements.indexOf(target) === 0) {
          this.focusSearchInput();
        } else {
          this.focusNextItem(event, elements, -1);
        }
      } else if (code === ARROW_DOWN_KEY) {
        this.focusNextItem(event, elements, 1);
      } else if (code === ESC_KEY) {
        this.$refs.modal.close();
      } else if (code === NUMPAD_ENTER_KEY) {
        event.target?.firstChild.click();
      } else {
        stop = false;
      }

      if (stop) {
        event.preventDefault();
      }
    },
    focusSearchInput() {
      this.$refs.searchInput.$el.querySelector('input')?.focus();
    },
    focusNextItem(event, elements, offset) {
      const { target } = event;
      const currentIndex = elements.indexOf(target);
      const nextIndex = clamp(currentIndex + offset, 0, elements.length - 1);

      this.focusItem(nextIndex, elements);
    },
    focusItem(index, elements) {
      this.nextFocusedItemIndex = index;

      elements[index]?.focus();
    },
  },
};
