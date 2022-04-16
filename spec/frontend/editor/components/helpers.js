import { EDITOR_TOOLBAR_RIGHT_GROUP } from '~/editor/constants';

export const buildButton = (id = 'foo-bar-btn', options = {}) => {
  return {
    __typename: 'Item',
    id,
    label: options.label || 'Foo Bar Button',
    icon: options.icon || 'foo-bar',
    selected: options.selected || false,
    group: options.group || EDITOR_TOOLBAR_RIGHT_GROUP,
  };
};
