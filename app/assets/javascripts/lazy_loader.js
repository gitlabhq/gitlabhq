import _ from 'underscore';

export const placeholderImage = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';
const SCROLL_THRESHOLD = 300;

export default class LazyLoader {
  constructor(options = {}) {
    this.lazyImages = [];
    this.observerNode = options.observerNode || '#content-body';

    const throttledScrollCheck = _.throttle(() => this.scrollCheck(), 300);
    const debouncedElementsInView = _.debounce(() => this.checkElementsInView(), 300);

    window.addEventListener('scroll', throttledScrollCheck);
    window.addEventListener('resize', debouncedElementsInView);

    const scrollContainer = options.scrollContainer || window;
    scrollContainer.addEventListener('load', () => this.loadCheck());
  }
  searchLazyImages() {
    this.lazyImages = [].slice.call(document.querySelectorAll('.lazy'));

    if (this.lazyImages.length) {
      this.checkElementsInView();
    }
  }
  startContentObserver() {
    const contentNode = document.querySelector(this.observerNode) || document.querySelector('body');

    if (contentNode) {
      const observer = new MutationObserver(() => this.searchLazyImages());

      observer.observe(contentNode, {
        childList: true,
        subtree: true,
      });
    }
  }
  loadCheck() {
    this.searchLazyImages();
    this.startContentObserver();
  }
  scrollCheck() {
    requestAnimationFrame(() => this.checkElementsInView());
  }
  checkElementsInView() {
    const scrollTop = pageYOffset;
    const visHeight = scrollTop + innerHeight + SCROLL_THRESHOLD;

    // Loading Images which are in the current viewport or close to them
    this.lazyImages = this.lazyImages.filter((selectedImage) => {
      if (selectedImage.getAttribute('data-src')) {
        const imgBoundRect = selectedImage.getBoundingClientRect();
        const imgTop = scrollTop + imgBoundRect.top;
        const imgBound = imgTop + imgBoundRect.height;

        if (scrollTop < imgBound && visHeight > imgTop) {
          LazyLoader.loadImage(selectedImage);
          return false;
        }

        return true;
      }
      return false;
    });
  }
  static loadImage(img) {
    if (img.getAttribute('data-src')) {
      img.setAttribute('src', img.getAttribute('data-src'));
      img.removeAttribute('data-src');
      img.classList.remove('lazy');
      img.classList.add('js-lazy-loaded');
    }
  }
}
