import Vue from 'vue';
import ToolbarItem from './toolbar_item.vue';

const buildWrapper = propsData => {
  const instance = new Vue({
    render(createElement) {
      return createElement(ToolbarItem, propsData);
    },
  });

  instance.$mount();
  return instance.$el;
};

// eslint-disable-next-line import/prefer-default-export
export const generateToolbarItem = config => {
  const { icon, classes, event, command, tooltip, isDivider } = config;

  if (isDivider) {
    return 'divider';
  }

  return {
    type: 'button',
    options: {
      el: buildWrapper({ props: { icon }, class: classes }),
      event,
      command,
      tooltip,
    },
  };
};
