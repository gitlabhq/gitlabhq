import Vue from 'vue';
import ListboxInput from '~/vue_shared/components/listbox_input/listbox_input.vue';

export const initListboxInputs = () => {
  const els = [...document.querySelectorAll('.js-listbox-input')];

  els.forEach((el, index) => {
    const { label, description, name, defaultToggleText, value = null } = el.dataset;
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
            items,
          },
          attrs: {
            id,
          },
        });
      },
    });
  });
};
