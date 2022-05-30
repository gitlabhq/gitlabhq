import Vue from 'vue';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import initDeleteTagModal from '../../../app/assets/javascripts/tags/init_delete_tag_modal';

describe('initDeleteTagModal', () => {
  beforeEach(() => {
    setHTMLFixture('<div class="js-delete-tag-modal"></div>');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('should mount the delete tag modal', () => {
    expect(initDeleteTagModal()).toBeInstanceOf(Vue);
    expect(document.querySelector('.js-delete-tag-modal')).toBeNull();
  });

  it('should return false if the mounting element is missing', () => {
    document.querySelector('.js-delete-tag-modal').remove();
    expect(initDeleteTagModal()).toBe(false);
  });
});
