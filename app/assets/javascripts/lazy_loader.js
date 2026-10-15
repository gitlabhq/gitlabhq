import { appendWidthToAvatarUrl } from '~/vue_shared/components/user_avatar/utils';

export const placeholderImage =
  'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';

export default class LazyLoader {
  constructor(options = {}) {
    this.observerNode = options.observerNode || '#content-body';

    const scrollContainer = options.scrollContainer || window;
    scrollContainer.addEventListener('load', () => this.register());
  }

  // eslint-disable-next-line class-methods-use-this -- called as `gl.lazyLoader.searchLazyImages()`
  searchLazyImages() {
    window.requestIdleCallback(
      () => {
        document.querySelectorAll('.lazy').forEach((img) => LazyLoader.loadImage(img));
      },
      { timeout: 500 },
    );
  }

  startContentObserver() {
    const contentNode = document.querySelector(this.observerNode) || document.querySelector('body');
    if (contentNode && !this.mutationObserver) {
      this.mutationObserver = new MutationObserver(() => this.searchLazyImages());

      this.mutationObserver.observe(contentNode, {
        childList: true,
        subtree: true,
      });
    }
  }

  register() {
    this.startContentObserver();
    this.searchLazyImages();
  }

  static loadImage(img) {
    if (img.dataset.src) {
      img.setAttribute('loading', 'lazy');
      let imgUrl = img.dataset.src;
      // eslint-disable-next-line @gitlab/no-hardcoded-urls -- URL substring pattern check to detect avatar image paths, not a navigational URL
      if (imgUrl.indexOf('/avatar/') > -1) {
        const targetWidth = img.getAttribute('width') || img.width;
        imgUrl = appendWidthToAvatarUrl(imgUrl, targetWidth);
      }
      img.setAttribute('src', imgUrl);
      // eslint-disable-next-line no-param-reassign
      delete img.dataset.src;
      img.classList.remove('lazy');
      img.classList.add('js-lazy-loaded');
      // eslint-disable-next-line no-param-reassign
      img.dataset.testid = 'js-lazy-loaded-content';
    }
  }
}
