import { setCookie, getCookie, parseBoolean } from '~/lib/utils/common_utils';
import { COOKIE_EXPIRATION, COOKIE_SUFFIX } from './constants';

const buildKey = (currentVersion) => {
  return `${currentVersion}${COOKIE_SUFFIX}`;
};

export const setHideAlertModalCookie = (currentVersion) => {
  const key = buildKey(currentVersion);

  setCookie(key, true, { expires: COOKIE_EXPIRATION });
};

export const getHideAlertModalCookie = (currentVersion) => {
  const key = buildKey(currentVersion);

  return parseBoolean(getCookie(key));
};
