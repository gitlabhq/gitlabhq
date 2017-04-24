import { borderlessIcons, baseIcons } from './ci_status_svg_index';

export function normalizeStatus(status) {
  // Supports the same syntax as the existing ruby helper and plain status strings.
  const legacyPrefix = /icon_status_/gi;
  return status.replace(legacyPrefix, '');
}

export function getCiStatusSvg({ status, borderless }) {
  const normalizedStatus = normalizeStatus(status);

  const fallbackStatus = 'canceled';

  if (borderless) {
    return borderlessIcons[normalizedStatus] || borderlessIcons[fallbackStatus];
  }

  return baseIcons[normalizedStatus] || baseIcons[fallbackStatus];
}
