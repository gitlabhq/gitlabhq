import { TEST_HOST } from 'helpers/test_constants';
import * as utilsHelper from '~/image_diff/helpers/utils_helper';
import ImageBadge from '~/image_diff/image_badge';
import * as mockData from '../mock_data';

describe('utilsHelper', () => {
  const { noteId, discussionId, image, imageProperties, imageMeta } = mockData;

  describe('resizeCoordinatesToImageElement', () => {
    let result;

    beforeEach(() => {
      result = utilsHelper.resizeCoordinatesToImageElement(image, imageMeta);
    });

    it('should return x based on widthRatio', () => {
      expect(result.x).toEqual(imageMeta.x * 0.5);
    });

    it('should return y based on heightRatio', () => {
      expect(result.y).toEqual(imageMeta.y * 0.5);
    });

    it('should return image width', () => {
      expect(result.width).toEqual(image.width);
    });

    it('should return image height', () => {
      expect(result.height).toEqual(image.height);
    });
  });

  describe('generateBadgeFromDiscussionDOM', () => {
    let discussionEl;
    let result;

    beforeEach(() => {
      const imageFrameEl = document.createElement('div');
      imageFrameEl.innerHTML = `
        <img src="${TEST_HOST}/image.png">
      `;
      discussionEl = document.createElement('div');
      discussionEl.dataset.discussionId = discussionId;
      discussionEl.innerHTML = `
        <div class="note" id="${noteId}"></div>
      `;
      discussionEl.dataset.position = JSON.stringify(imageMeta);
      result = utilsHelper.generateBadgeFromDiscussionDOM(imageFrameEl, discussionEl);
    });

    it('should return actual image properties', () => {
      const { actual } = result;

      expect(actual.x).toEqual(imageMeta.x);
      expect(actual.y).toEqual(imageMeta.y);
      expect(actual.width).toEqual(imageMeta.width);
      expect(actual.height).toEqual(imageMeta.height);
    });

    it('should return browser image properties', () => {
      const { browser } = result;

      expect(browser.x).toBeDefined();
      expect(browser.y).toBeDefined();
      expect(browser.width).toBeDefined();
      expect(browser.height).toBeDefined();
    });

    it('should return instance of ImageBadge', () => {
      expect(result instanceof ImageBadge).toEqual(true);
    });

    it('should return noteId', () => {
      expect(result.noteId).toEqual(noteId);
    });

    it('should return discussionId', () => {
      expect(result.discussionId).toEqual(discussionId);
    });
  });

  describe('getTargetSelection', () => {
    let containerEl;

    beforeEach(() => {
      containerEl = {
        querySelector: () => imageProperties,
      };
    });

    function generateEvent(offsetX, offsetY) {
      return {
        currentTarget: containerEl,
        offsetX,
        offsetY,
      };
    }

    it('should return browser properties', () => {
      const event = generateEvent(25, 25);
      const result = utilsHelper.getTargetSelection(event);

      const { browser } = result;

      expect(browser.x).toEqual(event.offsetX);
      expect(browser.y).toEqual(event.offsetY);
      expect(browser.width).toEqual(imageProperties.width);
      expect(browser.height).toEqual(imageProperties.height);
    });

    it('should return resized actual image properties', () => {
      const event = generateEvent(50, 50);
      const result = utilsHelper.getTargetSelection(event);

      const { actual } = result;

      expect(actual.x).toEqual(100);
      expect(actual.y).toEqual(100);
      expect(actual.width).toEqual(imageProperties.naturalWidth);
      expect(actual.height).toEqual(imageProperties.naturalHeight);
    });

    describe('normalize coordinates', () => {
      it('should return x = 0 if x < 0', () => {
        const event = generateEvent(-5, 50);
        const result = utilsHelper.getTargetSelection(event);

        expect(result.browser.x).toEqual(0);
      });

      it('should return x = width if x > width', () => {
        const event = generateEvent(1000, 50);
        const result = utilsHelper.getTargetSelection(event);

        expect(result.browser.x).toEqual(imageProperties.width);
      });

      it('should return y = 0 if y < 0', () => {
        const event = generateEvent(50, -10);
        const result = utilsHelper.getTargetSelection(event);

        expect(result.browser.y).toEqual(0);
      });

      it('should return y = height if y > height', () => {
        const event = generateEvent(50, 1000);
        const result = utilsHelper.getTargetSelection(event);

        expect(result.browser.y).toEqual(imageProperties.height);
      });
    });
  });
});
