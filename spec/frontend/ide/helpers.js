import { WEB_IDE_OAUTH_CALLBACK_URL_PATH } from '~/ide/constants';
import { decorateData } from '~/ide/stores/utils';

// eslint-disable-next-line max-params
export const file = (name = 'name', id = name, type = '', parent = null) =>
  decorateData({
    id,
    type,
    icon: 'icon',
    name,
    path: parent ? `${parent.path}/${name}` : name,
    parentPath: parent ? parent.path : '',
  });

export const getMockCallbackUrl = () =>
  new URL(WEB_IDE_OAUTH_CALLBACK_URL_PATH, window.location.origin).toString();
