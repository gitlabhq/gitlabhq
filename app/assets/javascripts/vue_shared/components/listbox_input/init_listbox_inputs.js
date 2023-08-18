import Vue from 'vue';
import ListboxInput from '~/vue_shared/components/listbox_input/listbox_input.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export const initListboxInputs = () => {
  const els = [...document.querySelectorAll('.js-listbox-input')];

  els.forEach((el, index) => {
    const { label, description, name, defaultToggleText, value = null, toggleClass } = el.dataset;
    const { id } = el;
    const items = JSON.parse(el.dataset.items);

    return new Vue({
      el,
      name: `ListboxInputRoot${index + 1}`,
      data() {
        return {
          selected: value,
        };
      },
      render(createElement) {
        return createElement(ListboxInput, {
          on: {
            select: (newValue) => {
              this.selected = newValue;
            },
          },
          props: {
            label,
            description,
            name,
            defaultToggleText,
            selected: this.selected,
            block: parseBoolean(el.dataset.block),
            fluidWidth: parseBoolean(el.dataset.fluidWidth),
            items,
            toggleClass,
          },
          attrs: {
            id,
          },
        });
      },
    });
  });
};
