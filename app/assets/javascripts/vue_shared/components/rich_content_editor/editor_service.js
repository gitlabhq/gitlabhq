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

export const addCustomEventListener = (editorApi, event, handler) => {
  editorApi.eventManager.addEventType(event);
  editorApi.eventManager.listen(event, handler);
};

export const removeCustomEventListener = (editorApi, event, handler) =>
  editorApi.eventManager.removeEventHandler(event, handler);

export const addImage = ({ editor }, image) => editor.exec('AddImage', image);

export const getMarkdown = editorInstance => editorInstance.invoke('getMarkdown');
