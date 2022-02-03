import * as domHelper from '~/image_diff/helpers/dom_helper';
import * as mockData from '../mock_data';

describe('domHelper', () => {
  const { imageMeta, badgeNumber } = mockData;

  describe('setPositionDataAttribute', () => {
    let containerEl;
    let attributeAfterCall;
    const position = {
      myProperty: 'myProperty',
    };

    beforeEach(() => {
      containerEl = document.createElement('div');
      containerEl.dataset.position = JSON.stringify(position);
      domHelper.setPositionDataAttribute(containerEl, imageMeta);
      attributeAfterCall = JSON.parse(containerEl.dataset.position);
    });

    it('should set x, y, width, height', () => {
      expect(attributeAfterCall.x).toEqual(imageMeta.x);
      expect(attributeAfterCall.y).toEqual(imageMeta.y);
      expect(attributeAfterCall.width).toEqual(imageMeta.width);
      expect(attributeAfterCall.height).toEqual(imageMeta.height);
    });

    it('should not override other properties', () => {
      expect(attributeAfterCall.myProperty).toEqual('myProperty');
    });
  });

  describe('updateDiscussionAvatarBadgeNumber', () => {
    let discussionEl;

    beforeEach(() => {
      discussionEl = document.createElement('div');
      discussionEl.innerHTML = `
        <a href="#" class="image-diff-avatar-link">
          <div class="design-note-pin"></div>
        </a>
      `;
      domHelper.updateDiscussionAvatarBadgeNumber(discussionEl, badgeNumber);
    });

    it('should update avatar badge number', () => {
      expect(discussionEl.querySelector('.design-note-pin').textContent).toEqual(
        badgeNumber.toString(),
      );
    });
  });

  describe('updateDiscussionBadgeNumber', () => {
    let discussionEl;

    beforeEach(() => {
      discussionEl = document.createElement('div');
      discussionEl.innerHTML = `
        <div class="design-note-pin"></div>
      `;
      domHelper.updateDiscussionBadgeNumber(discussionEl, badgeNumber);
    });

    it('should update discussion badge number', () => {
      expect(discussionEl.querySelector('.design-note-pin').textContent).toEqual(
        badgeNumber.toString(),
      );
    });
  });

  describe('toggleCollapsed', () => {
    let element;
    let discussionNotesEl;

    beforeEach(() => {
      element = document.createElement('div');
      element.innerHTML = `
        <div class="discussion-notes">
          <button></button>
          <form class="discussion-form"></form>
        </div>
      `;
      discussionNotesEl = element.querySelector('.discussion-notes');
    });

    describe('not collapsed', () => {
      beforeEach(() => {
        domHelper.toggleCollapsed({
          currentTarget: element.querySelector('button'),
        });
      });

      it('should add collapsed class', () => {
        expect(discussionNotesEl.classList.contains('collapsed')).toEqual(true);
      });

      it('should force formEl to display none', () => {
        const formEl = element.querySelector('.discussion-form');

        expect(formEl.style.display).toEqual('none');
      });
    });

    describe('collapsed', () => {
      beforeEach(() => {
        discussionNotesEl.classList.add('collapsed');

        domHelper.toggleCollapsed({
          currentTarget: element.querySelector('button'),
        });
      });

      it('should remove collapsed class', () => {
        expect(discussionNotesEl.classList.contains('collapsed')).toEqual(false);
      });

      it('should force formEl to display block', () => {
        const formEl = element.querySelector('.discussion-form');

        expect(formEl.style.display).toEqual('block');
      });
    });
  });
});
