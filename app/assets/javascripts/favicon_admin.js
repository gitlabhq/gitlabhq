import {createOverlayIcon} from '~/lib/utils/common_utils';

export default class FaviconAdmin {
  constructor() {
    const faviconContainer = $('.js-favicons');
    const faviconUrl = faviconContainer.data('favicon');
    const overlayUrls = faviconContainer.data('status-overlays') || [];

    overlayUrls.forEach((statusOverlay) => {
      createOverlayIcon(faviconUrl, statusOverlay).then((faviconWithOverlayUrl) => {
        const image = $('<img />');
        image.addClass('appearance-light-logo-preview');
        image.attr('src', faviconWithOverlayUrl);

        faviconContainer.append(image);
      });
    });
  }
}
