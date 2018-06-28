import _ from 'underscore';

/**
 * This method is based on app/helpers/avatars_helper.rb#project_identicon
 */
function getIdenticonStyles(entityId) {
  const allowedColors = [
    '#FFEBEE',
    '#F3E5F5',
    '#E8EAF6',
    '#E3F2FD',
    '#E0F2F1',
    '#FBE9E7',
    '#EEEEEE',
  ];

  const backgroundColor = allowedColors[entityId % allowedColors.length];

  return `background-color: ${backgroundColor}; color: #555;`;
}

function getIdenticonTitle(entityName) {
  return entityName.charAt(0).toUpperCase();
}

export function renderIdenticon(id, name, options = {}) {
  const { sizeClass = 's32' } = options;

  const styles = getIdenticonStyles(id);
  const title = getIdenticonTitle(name);

  return `<div style="${_.escape(styles)}" class="avatar identicon ${_.escape(sizeClass)}">${_.escape(title)}</div>`;
}

export function renderAvatar(entity, options = {}) {
  const { sizeClass = 's32' } = options;

  if (!entity.avatar_url) {
    return renderIdenticon(entity.id, entity.name, options);
  }

  return `<img src="${_.escape(entity.avatar_url)}" class="avatar ${_.escape(sizeClass)}" />`;
}
