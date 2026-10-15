import { useMockMutationObserver } from 'helpers/mock_dom_observer';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import LazyLoader from '~/lazy_loader';

const execImmediately = (callback) => {
  callback();
};

const TEST_PATH = `${TEST_HOST}/img/testimg.png`;
const TEST_AVATAR_PATH = `${TEST_HOST}/uploads/-/system/project/avatar/1/avatar.png`;
const TEST_AVATAR_PATH_WITH_QUERY = `${TEST_AVATAR_PATH}?v=123`;

describe('LazyLoader', () => {
  let lazyLoader = null;

  const { trigger: triggerMutation } = useMockMutationObserver();

  const triggerChildMutation = () => {
    triggerMutation(document.body, { options: { childList: true, subtree: true } });
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
    jest.spyOn(window, 'requestIdleCallback').mockImplementation(execImmediately);

    mockLoadEvent();

    lazyLoader = new LazyLoader({
      observerNode: 'foobar',
    });
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  it('should copy value from data-src to src for img 1', () => {
    const img = createLazyLoadImage();

    // Doing everything that happens normally in onload
    lazyLoader.register();

    expect(img.getAttribute('src')).toBe(TEST_PATH);
    expect(img.getAttribute('loading')).toBe('lazy');
    expect(img.dataset.src).toBeUndefined();
    expect(img).toHaveClass('js-lazy-loaded');
  });

  it('should lazy load dynamically added data-src images', async () => {
    lazyLoader.register();

    const newImg = createLazyLoadImage();

    await waitForPromises();

    expect(newImg.getAttribute('src')).toBe(TEST_PATH);
    expect(newImg).toHaveClass('js-lazy-loaded');
  });

  it('should not alter normal images', () => {
    const newImg = createImage();

    lazyLoader.register();

    expect(newImg).not.toHaveClass('js-lazy-loaded');
  });

  describe('avatar URLs', () => {
    const createAvatarImageAndLoad = (imageSource) => {
      const img = document.createElement('img');
      img.className = 'lazy';
      img.dataset.src = imageSource;
      img.width = 64;
      document.body.appendChild(img);
      triggerChildMutation();

      lazyLoader.register();

      return img;
    };

    it('should append width to avatar URLs without query params', () => {
      const img = createAvatarImageAndLoad(TEST_AVATAR_PATH);

      expect(img.getAttribute('src')).toBe(`${TEST_AVATAR_PATH}?width=64`);
    });

    it('should append width to avatar URLs that already have query params', () => {
      const img = createAvatarImageAndLoad(TEST_AVATAR_PATH_WITH_QUERY);

      expect(img.getAttribute('src')).toBe(`${TEST_AVATAR_PATH_WITH_QUERY}&width=64`);
    });

    it('should not append width to avatar URLs that already have a width parameter', () => {
      const img = createAvatarImageAndLoad(`${TEST_AVATAR_PATH}?width=32&v=123`);

      expect(img.getAttribute('src')).toBe(`${TEST_AVATAR_PATH}?width=32&v=123`);
    });
  });
});
