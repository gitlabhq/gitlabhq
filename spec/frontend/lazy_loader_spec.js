import { noop } from 'lodash';
import { useMockMutationObserver, useMockIntersectionObserver } from 'helpers/mock_dom_observer';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import LazyLoader from '~/lazy_loader';

const execImmediately = (callback) => {
  callback();
};

const TEST_PATH = `${TEST_HOST}/img/testimg.png`;

describe('LazyLoader', () => {
  let lazyLoader = null;

  const { trigger: triggerMutation } = useMockMutationObserver();
  const { trigger: triggerIntersection } = useMockIntersectionObserver();

  const triggerChildMutation = () => {
    triggerMutation(document.body, { options: { childList: true, subtree: true } });
  };

  const triggerIntersectionWithRatio = (img) => {
    triggerIntersection(img, { entry: { intersectionRatio: 0.1 } });
  };

  const createLazyLoadImage = () => {
    const newImg = document.createElement('img');
    newImg.className = 'lazy';
    newImg.dataset.src = TEST_PATH;

    document.body.appendChild(newImg);
    triggerChildMutation();

    return newImg;
  };

  const createImage = () => {
    const newImg = document.createElement('img');
    newImg.setAttribute('src', TEST_PATH);

    document.body.appendChild(newImg);
    triggerChildMutation();

    return newImg;
  };

  const mockLoadEvent = () => {
    const addEventListener = window.addEventListener.bind(window);

    jest.spyOn(window, 'addEventListener').mockImplementation((event, callback) => {
      if (event === 'load') {
        callback();
      } else {
        addEventListener(event, callback);
      }
    });
  };

  beforeEach(() => {
    jest.spyOn(window, 'requestAnimationFrame').mockImplementation(execImmediately);
    jest.spyOn(window, 'requestIdleCallback').mockImplementation(execImmediately);

    mockLoadEvent();
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe.each`
    hasIntersectionObserver | trigger
    ${true}                 | ${triggerIntersectionWithRatio}
    ${false}                | ${noop}
  `(
    'with hasIntersectionObserver=$hasIntersectionObserver',
    ({ hasIntersectionObserver, trigger }) => {
      let origIntersectionObserver;

      beforeEach(() => {
        origIntersectionObserver = global.IntersectionObserver;
        global.IntersectionObserver = hasIntersectionObserver
          ? global.IntersectionObserver
          : undefined;

        lazyLoader = new LazyLoader({
          observerNode: 'foobar',
        });
      });

      afterEach(() => {
        global.IntersectionObserver = origIntersectionObserver;
        lazyLoader.unregister();
      });

      it('determines intersection observer support', () => {
        expect(LazyLoader.supportsIntersectionObserver()).toBe(hasIntersectionObserver);
      });

      it('should copy value from data-src to src for img 1', () => {
        const img = createLazyLoadImage();

        // Doing everything that happens normally in onload
        lazyLoader.register();

        trigger(img);

        expect(img.getAttribute('src')).toBe(TEST_PATH);
        expect(img.dataset.src).toBeUndefined();
        expect(img).toHaveClass('js-lazy-loaded');
      });

      it('should lazy load dynamically added data-src images', async () => {
        lazyLoader.register();

        const newImg = createLazyLoadImage();

        trigger(newImg);

        await waitForPromises();

        expect(newImg.getAttribute('src')).toBe(TEST_PATH);
        expect(newImg).toHaveClass('js-lazy-loaded');
      });

      it('should not alter normal images', () => {
        const newImg = createImage();

        lazyLoader.register();

        expect(newImg).not.toHaveClass('js-lazy-loaded');
      });

      it('should not load dynamically added pictures if content observer is turned off', async () => {
        lazyLoader.register();
        lazyLoader.stopContentObserver();

        const newImg = createLazyLoadImage();

        await waitForPromises();

        expect(newImg).not.toHaveClass('js-lazy-loaded');
      });

      it('should load dynamically added pictures if content observer is turned off and on again', async () => {
        lazyLoader.register();
        lazyLoader.stopContentObserver();
        lazyLoader.startContentObserver();

        const newImg = createLazyLoadImage();

        trigger(newImg);

        await waitForPromises();

        expect(newImg.getAttribute('src')).toBe(TEST_PATH);
        expect(newImg).toHaveClass('js-lazy-loaded');
      });
    },
  );
});
