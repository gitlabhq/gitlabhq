import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import imageDiffHelper from '~/image_diff/helpers/index';
import ImageDiff from '~/image_diff/image_diff';
import ReplacedImageDiff from '~/image_diff/replaced_image_diff';
import { viewTypes } from '~/image_diff/view_types';

describe('ReplacedImageDiff', () => {
  let element;
  let replacedImageDiff;

  beforeEach(() => {
    setHTMLFixture(`
      <div id="element">
        <div class="two-up">
          <div class="js-image-frame">
            <img src="${TEST_HOST}/image.png">
          </div>
        </div>
        <div class="swipe">
          <div class="js-image-frame">
            <img src="${TEST_HOST}/image.png">
          </div>
        </div>
        <div class="onion-skin">
          <div class="js-image-frame">
            <img src="${TEST_HOST}/image.png">
          </div>
        </div>
        <div class="view-modes-menu">
          <div class="two-up">2-up</div>
          <div class="swipe">Swipe</div>
          <div class="onion-skin">Onion skin</div>
        </div>
      </div>
    `);
    element = document.getElementById('element');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  function setupImageFrameEls() {
    replacedImageDiff.imageFrameEls = [];
    replacedImageDiff.imageFrameEls[viewTypes.TWO_UP] =
      element.querySelector('.two-up .js-image-frame');
    replacedImageDiff.imageFrameEls[viewTypes.SWIPE] =
      element.querySelector('.swipe .js-image-frame');
    replacedImageDiff.imageFrameEls[viewTypes.ONION_SKIN] = element.querySelector(
      '.onion-skin .js-image-frame',
    );
  }

  function setupViewModesEls() {
    replacedImageDiff.viewModesEls = [];
    replacedImageDiff.viewModesEls[viewTypes.TWO_UP] = element.querySelector(
      '.view-modes-menu .two-up',
    );
    replacedImageDiff.viewModesEls[viewTypes.SWIPE] =
      element.querySelector('.view-modes-menu .swipe');
    replacedImageDiff.viewModesEls[viewTypes.ONION_SKIN] = element.querySelector(
      '.view-modes-menu .onion-skin',
    );
  }

  function setupImageEls() {
    replacedImageDiff.imageEls = [];
    replacedImageDiff.imageEls[viewTypes.TWO_UP] = element.querySelector('.two-up img');
    replacedImageDiff.imageEls[viewTypes.SWIPE] = element.querySelector('.swipe img');
    replacedImageDiff.imageEls[viewTypes.ONION_SKIN] = element.querySelector('.onion-skin img');
  }

  it('should extend ImageDiff', () => {
    replacedImageDiff = new ReplacedImageDiff(element);

    expect(replacedImageDiff instanceof ImageDiff).toEqual(true);
  });

  describe('init', () => {
    beforeEach(() => {
      jest.spyOn(ReplacedImageDiff.prototype, 'bindEvents').mockImplementation(() => {});
      jest.spyOn(ReplacedImageDiff.prototype, 'generateImageEls').mockImplementation(() => {});

      replacedImageDiff = new ReplacedImageDiff(element);
      replacedImageDiff.init();
    });

    it('should set imageFrameEls', () => {
      const { imageFrameEls } = replacedImageDiff;

      expect(imageFrameEls).toBeDefined();
      expect(imageFrameEls[viewTypes.TWO_UP]).toEqual(
        element.querySelector('.two-up .js-image-frame'),
      );

      expect(imageFrameEls[viewTypes.SWIPE]).toEqual(
        element.querySelector('.swipe .js-image-frame'),
      );

      expect(imageFrameEls[viewTypes.ONION_SKIN]).toEqual(
        element.querySelector('.onion-skin .js-image-frame'),
      );
    });

    it('should set viewModesEls', () => {
      const { viewModesEls } = replacedImageDiff;

      expect(viewModesEls).toBeDefined();
      expect(viewModesEls[viewTypes.TWO_UP]).toEqual(
        element.querySelector('.view-modes-menu .two-up'),
      );

      expect(viewModesEls[viewTypes.SWIPE]).toEqual(
        element.querySelector('.view-modes-menu .swipe'),
      );

      expect(viewModesEls[viewTypes.ONION_SKIN]).toEqual(
        element.querySelector('.view-modes-menu .onion-skin'),
      );
    });

    it('should generateImageEls', () => {
      expect(ReplacedImageDiff.prototype.generateImageEls).toHaveBeenCalled();
    });

    it('should bindEvents', () => {
      expect(ReplacedImageDiff.prototype.bindEvents).toHaveBeenCalled();
    });

    describe('currentView', () => {
      it('should set currentView', () => {
        replacedImageDiff.init(viewTypes.ONION_SKIN);

        expect(replacedImageDiff.currentView).toEqual(viewTypes.ONION_SKIN);
      });

      it('should default to viewTypes.TWO_UP', () => {
        expect(replacedImageDiff.currentView).toEqual(viewTypes.TWO_UP);
      });
    });
  });

  describe('generateImageEls', () => {
    beforeEach(() => {
      jest.spyOn(ReplacedImageDiff.prototype, 'bindEvents').mockImplementation(() => {});

      replacedImageDiff = new ReplacedImageDiff(element, {
        canCreateNote: false,
        renderCommentBadge: false,
      });

      setupImageFrameEls();
    });

    it('should set imageEls', () => {
      replacedImageDiff.generateImageEls();
      const { imageEls } = replacedImageDiff;

      expect(imageEls).toBeDefined();
      expect(imageEls[viewTypes.TWO_UP]).toEqual(element.querySelector('.two-up img'));
      expect(imageEls[viewTypes.SWIPE]).toEqual(element.querySelector('.swipe img'));
      expect(imageEls[viewTypes.ONION_SKIN]).toEqual(element.querySelector('.onion-skin img'));
    });
  });

  describe('bindEvents', () => {
    beforeEach(() => {
      jest.spyOn(ImageDiff.prototype, 'bindEvents').mockImplementation(() => {});
      replacedImageDiff = new ReplacedImageDiff(element);

      setupViewModesEls();
    });

    it('should call super.bindEvents', () => {
      replacedImageDiff.bindEvents();

      expect(ImageDiff.prototype.bindEvents).toHaveBeenCalled();
    });

    it('should register click eventlistener to 2-up view mode', () => {
      const changeViewSpy = jest
        .spyOn(ReplacedImageDiff.prototype, 'changeView')
        .mockImplementation(() => {});

      replacedImageDiff.bindEvents();
      replacedImageDiff.viewModesEls[viewTypes.TWO_UP].click();

      expect(changeViewSpy).toHaveBeenCalledWith(viewTypes.TWO_UP, expect.any(Object));
    });

    it('should register click eventlistener to swipe view mode', () => {
      const changeViewSpy = jest
        .spyOn(ReplacedImageDiff.prototype, 'changeView')
        .mockImplementation(() => {});

      replacedImageDiff.bindEvents();
      replacedImageDiff.viewModesEls[viewTypes.SWIPE].click();

      expect(changeViewSpy).toHaveBeenCalledWith(viewTypes.SWIPE, expect.any(Object));
    });

    it('should register click eventlistener to onion skin view mode', () => {
      const changeViewSpy = jest
        .spyOn(ReplacedImageDiff.prototype, 'changeView')
        .mockImplementation(() => {});

      replacedImageDiff.bindEvents();
      replacedImageDiff.viewModesEls[viewTypes.SWIPE].click();
      expect(changeViewSpy).toHaveBeenCalledWith(viewTypes.SWIPE, expect.any(Object));
    });
  });

  describe('getters', () => {
    describe('imageEl', () => {
      beforeEach(() => {
        replacedImageDiff = new ReplacedImageDiff(element);
        replacedImageDiff.currentView = viewTypes.TWO_UP;
        setupImageEls();
      });

      it('should return imageEl based on currentView', () => {
        expect(replacedImageDiff.imageEl).toEqual(element.querySelector('.two-up img'));

        replacedImageDiff.currentView = viewTypes.SWIPE;

        expect(replacedImageDiff.imageEl).toEqual(element.querySelector('.swipe img'));
      });
    });

    describe('imageFrameEl', () => {
      beforeEach(() => {
        replacedImageDiff = new ReplacedImageDiff(element);
        replacedImageDiff.currentView = viewTypes.TWO_UP;
        setupImageFrameEls();
      });

      it('should return imageFrameEl based on currentView', () => {
        expect(replacedImageDiff.imageFrameEl).toEqual(
          element.querySelector('.two-up .js-image-frame'),
        );

        replacedImageDiff.currentView = viewTypes.ONION_SKIN;

        expect(replacedImageDiff.imageFrameEl).toEqual(
          element.querySelector('.onion-skin .js-image-frame'),
        );
      });
    });
  });

  describe('changeView', () => {
    beforeEach(() => {
      replacedImageDiff = new ReplacedImageDiff(element);
      jest.spyOn(imageDiffHelper, 'removeCommentIndicator').mockReturnValue({
        removed: false,
      });
      setupImageFrameEls();
    });

    describe('invalid viewType', () => {
      beforeEach(() => {
        replacedImageDiff.changeView('some-view-name');
      });

      it('should not call removeCommentIndicator', () => {
        expect(imageDiffHelper.removeCommentIndicator).not.toHaveBeenCalled();
      });
    });

    describe('valid viewType', () => {
      beforeEach(() => {
        jest.spyOn(ReplacedImageDiff.prototype, 'renderNewView').mockImplementation(() => {});
        replacedImageDiff.changeView(viewTypes.ONION_SKIN);
      });

      afterEach(() => {
        jest.clearAllTimers();
      });

      it('should call removeCommentIndicator', () => {
        expect(imageDiffHelper.removeCommentIndicator).toHaveBeenCalled();
      });

      it('should update currentView to newView', () => {
        expect(replacedImageDiff.currentView).toEqual(viewTypes.ONION_SKIN);
      });

      it('should clear imageBadges', () => {
        expect(replacedImageDiff.imageBadges.length).toEqual(0);
      });

      it('should call renderNewView', () => {
        jest.advanceTimersByTime(251);

        expect(replacedImageDiff.renderNewView).toHaveBeenCalled();
      });
    });
  });

  describe('renderNewView', () => {
    beforeEach(() => {
      replacedImageDiff = new ReplacedImageDiff(element);
    });

    it('should call renderBadges', () => {
      jest.spyOn(ReplacedImageDiff.prototype, 'renderBadges').mockImplementation(() => {});

      replacedImageDiff.renderNewView({
        removed: false,
      });

      expect(replacedImageDiff.renderBadges).toHaveBeenCalled();
    });

    describe('removeIndicator', () => {
      const indicator = {
        removed: true,
        x: 0,
        y: 1,
        image: {
          width: 50,
          height: 100,
        },
      };

      beforeEach(() => {
        setupImageEls();
        setupImageFrameEls();
      });

      it('should pass showCommentIndicator normalized indicator values', () => {
        jest.spyOn(imageDiffHelper, 'showCommentIndicator').mockImplementation(() => {});
        const resizeCoordinatesToImageElementSpy = jest
          .spyOn(imageDiffHelper, 'resizeCoordinatesToImageElement')
          .mockImplementation(() => {});

        replacedImageDiff.renderNewView(indicator);

        expect(resizeCoordinatesToImageElementSpy).toHaveBeenCalledWith(undefined, {
          x: indicator.x,
          y: indicator.y,
          width: indicator.image.width,
          height: indicator.image.height,
        });
      });

      it('should call showCommentIndicator', () => {
        const normalized = {
          normalized: true,
        };
        jest.spyOn(imageDiffHelper, 'resizeCoordinatesToImageElement').mockReturnValue(normalized);
        const showCommentIndicatorSpy = jest
          .spyOn(imageDiffHelper, 'showCommentIndicator')
          .mockImplementation(() => {});

        replacedImageDiff.renderNewView(indicator);

        expect(showCommentIndicatorSpy).toHaveBeenCalledWith(undefined, normalized);
      });
    });
  });
});
