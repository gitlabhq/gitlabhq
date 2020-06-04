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
      el: buildWrapper({ props: { icon, tooltip }, class: classes }),
      event,
      command,
    },
  };
};

export const addCustomEventListener = (editorInstance, event, handler) => {
  editorInstance.eventManager.addEventType(event);
  editorInstance.eventManager.listen(event, handler);
};

export const removeCustomEventListener = (editorInstance, event, handler) =>
  editorInstance.eventManager.removeEventHandler(event, handler);

export const addImage = ({ editor }, image) => editor.exec('AddImage', image);

export const getMarkdown = editorInstance => editorInstance.invoke('getMarkdown');
