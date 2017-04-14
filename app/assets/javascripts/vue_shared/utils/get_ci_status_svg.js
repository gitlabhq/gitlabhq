import { borderlessIcons, baseIcons } from './ci_status_svg_index';

export default function getCiStatusSvg({ status, borderless }) {
  // Supports the same syntax as the existing ruby helper, as well as status strings.
  const legacyPrefix = /icon_status_/gi;
  const normalizedStatus = status.replace(legacyPrefix, '');

  return borderless ? borderlessIcons[normalizedStatus] : baseIcons[normalizedStatus];
}

