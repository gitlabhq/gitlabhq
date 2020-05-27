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

export const addCustomEventListener = (editorInstance, event, handler) => {
  editorInstance.eventManager.addEventType(event);
  editorInstance.eventManager.listen(event, handler);
};
