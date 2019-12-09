import $ from 'jquery';
import { TEST_HOST } from 'helpers/test_constants';
import axios from '~/lib/utils/axios_utils';
import EmojiMenu from '~/pages/profiles/show/emoji_menu';

describe('EmojiMenu', () => {
  const dummyEmojiTag = '<dummy></tag>';
  const dummyToggleButtonSelector = '.toggle-button-selector';
  const dummyMenuClass = 'dummy-menu-class';

  let emojiMenu;
  let dummySelectEmojiCallback;
  let dummyEmojiList;

  beforeEach(() => {
    dummySelectEmojiCallback = jest.fn().mockName('dummySelectEmojiCallback');
    dummyEmojiList = {
      glEmojiTag() {
        return dummyEmojiTag;
      },
      normalizeEmojiName(emoji) {
        return emoji;
      },
      isEmojiNameValid() {
        return true;
      },
      getEmojiCategoryMap() {
        return { dummyCategory: [] };
      },
    };

    emojiMenu = new EmojiMenu(
      dummyEmojiList,
      dummyToggleButtonSelector,
      dummyMenuClass,
      dummySelectEmojiCallback,
    );
  });

  afterEach(() => {
    emojiMenu.destroy();
  });

  describe('addAward', () => {
    const dummyAwardUrl = `${TEST_HOST}/award/url`;
    const dummyEmoji = 'tropical_fish';
    const dummyVotesBlock = () => $('<div />');

    it('calls selectEmojiCallback', done => {
      expect(dummySelectEmojiCallback).not.toHaveBeenCalled();

      emojiMenu.addAward(dummyVotesBlock(), dummyAwardUrl, dummyEmoji, false, () => {
        expect(dummySelectEmojiCallback).toHaveBeenCalledWith(dummyEmoji, dummyEmojiTag);
        done();
      });
    });

    it('does not make an axios requst', done => {
      jest.spyOn(axios, 'request').mockReturnValue();

      emojiMenu.addAward(dummyVotesBlock(), dummyAwardUrl, dummyEmoji, false, () => {
        expect(axios.request).not.toHaveBeenCalled();
        done();
      });
    });
  });

  describe('bindEvents', () => {
    beforeEach(() => {
      jest.spyOn(emojiMenu, 'registerEventListener').mockReturnValue();
    });

    it('binds event listeners to custom toggle button', () => {
      emojiMenu.bindEvents();

      expect(emojiMenu.registerEventListener).toHaveBeenCalledWith(
        'one',
        expect.anything(),
        'mouseenter focus',
        dummyToggleButtonSelector,
        'mouseenter focus',
        expect.anything(),
      );

      expect(emojiMenu.registerEventListener).toHaveBeenCalledWith(
        'on',
        expect.anything(),
        'click',
        dummyToggleButtonSelector,
        expect.anything(),
      );
    });

    it('binds event listeners to custom menu class', () => {
      emojiMenu.bindEvents();

      expect(emojiMenu.registerEventListener).toHaveBeenCalledWith(
        'on',
        expect.anything(),
        'click',
        `.js-awards-block .js-emoji-btn, .${dummyMenuClass} .js-emoji-btn`,
        expect.anything(),
      );
    });
  });

  describe('createEmojiMenu', () => {
    it('renders the menu with custom menu class', () => {
      const menuElement = () =>
        document.body.querySelector(`.emoji-menu.${dummyMenuClass} .emoji-menu-content`);

      expect(menuElement()).toBe(null);

      emojiMenu.createEmojiMenu();

      expect(menuElement()).not.toBe(null);
    });
  });
});
