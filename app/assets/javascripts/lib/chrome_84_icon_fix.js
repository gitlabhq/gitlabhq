import svg4everybody from 'svg4everybody';

/*
  Chrome and Edge 84 have a bug relating to icon sprite svgs
  https://bugs.chromium.org/p/chromium/issues/detail?id=1107442

  If the SVG is loaded, under certain circumstances the icons are not
  shown. As a workaround we use the well-tested svg4everybody and forcefully
  include the icon fragments into the DOM and thus circumventing the bug
 */
document.addEventListener('DOMContentLoaded', () => {
  svg4everybody({ polyfill: true });
});
