import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import Cookies from 'js-cookie';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import loadAwardsHandler from '~/awards_handler';
import { EMOJI_VERSION } from '~/emoji';
import axios from '~/lib/utils/axios_utils';

window.gl = window.gl || {};
window.gon = window.gon || {};

let mock;
let awardsHandler = null;
const urlRoot = gon.relative_url_root;

describe('AwardsHandler', () => {
  useFakeRequestAnimationFrame();

  const emojiData = {
    '8ball': {
      c: 'activity',
      e: '🎱',
      d: 'billiards',
      u: '6.0',
    },
    grinning: {
      c: 'people',
      e: '😀',
      d: 'grinning face',
      u: '6.1',
    },
    angel: {
      c: 'people',
      e: '👼',
      d: 'baby angel',
      u: '6.0',
    },
    anger: {
      c: 'symbols',
      e: '💢',
      d: 'anger symbol',
      u: '6.0',
    },
    alien: {
      c: 'people',
      e: '👽',
      d: 'extraterrestrial alien',
      u: '6.0',
    },
    sunglasses: {
      c: 'people',
      e: '😎',
      d: 'smiling face with sunglasses',
      u: '6.0',
    },
    grey_question: {
      c: 'symbols',
      e: '❔',
      d: 'white question mark ornament',
      u: '6.0',
    },
  };

  const openAndWaitForEmojiMenu = (sel = '.js-add-award') => {
    $(sel).eq(0).click();

    jest.runOnlyPendingTimers();

    const $menu = $('.emoji-menu');

    return new Promise((resolve) => {
      $menu.one('build-emoji-menu-finish', () => {
        resolve();
      });
    });
  };

  beforeEach(async () => {
    mock = new MockAdapter(axios);
    mock.onGet(`/-/emojis/${EMOJI_VERSION}/emojis.json`).reply(200, emojiData);

    loadFixtures('snippets/show.html');

    awardsHandler = await loadAwardsHandler(true);
    jest.spyOn(awardsHandler, 'postEmoji').mockImplementation((button, url, emoji, cb) => cb());
  });

  afterEach(() => {
    // restore original url root value
    gon.relative_url_root = urlRoot;

    mock.restore();

    // Undo what we did to the shared <body>
    $('body').removeAttr('data-page');

    awardsHandler.destroy();
  });

  describe('::showEmojiMenu', () => {
    it('should show emoji menu when Add emoji button clicked', async () => {
      await openAndWaitForEmojiMenu();

      const $emojiMenu = $('.emoji-menu');

      expect($emojiMenu.length).toBe(1);
      expect($emojiMenu.hasClass('is-visible')).toBe(true);
      expect($emojiMenu.find('.js-emoji-menu-search').length).toBe(1);
      expect($('.js-awards-block.current').length).toBe(1);
    });

    it('should also show emoji menu for the smiley icon in notes', async () => {
      await openAndWaitForEmojiMenu('.js-add-award.note-action-button');

      const $emojiMenu = $('.emoji-menu');

      expect($emojiMenu.length).toBe(1);
    });

    it('should remove emoji menu when body is clicked', async () => {
      await openAndWaitForEmojiMenu();

      const $emojiMenu = $('.emoji-menu');
      $('body').click();

      expect($emojiMenu.length).toBe(1);
      expect($emojiMenu.hasClass('is-visible')).toBe(false);
      expect($('.js-awards-block.current').length).toBe(0);
    });

    it('should not remove emoji menu when search is clicked', async () => {
      await openAndWaitForEmojiMenu();

      const $emojiMenu = $('.emoji-menu');
      $('.emoji-search').click();

      expect($emojiMenu.length).toBe(1);
      expect($emojiMenu.hasClass('is-visible')).toBe(true);
      expect($('.js-awards-block.current').length).toBe(1);
    });
  });

  describe('::addAwardToEmojiBar', () => {
    it('should add emoji to votes block', () => {
      const $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      const $emojiButton = $votesBlock.find('[data-name=heart]');

      expect($emojiButton.length).toBe(1);
      expect($emojiButton.next('.js-counter').text()).toBe('1');
      expect($votesBlock.hasClass('hidden')).toBe(false);
    });

    it('should remove the emoji when we click again', () => {
      const $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      const $emojiButton = $votesBlock.find('[data-name=heart]');

      expect($emojiButton.length).toBe(0);
    });

    it('should decrement the emoji counter', () => {
      const $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);
      const $emojiButton = $votesBlock.find('[data-name=heart]');
      $emojiButton.next('.js-counter').text(5);
      awardsHandler.addAwardToEmojiBar($votesBlock, 'heart', false);

      expect($emojiButton.length).toBe(1);
      expect($emojiButton.next('.js-counter').text()).toBe('4');
    });
  });

  describe('::getAwardUrl', () => {
    it('returns the url for request', () => {
      expect(awardsHandler.getAwardUrl()).toBe('http://test.host/-/snippets/1/toggle_award_emoji');
    });
  });

  describe('::addAward and ::checkMutuality', () => {
    it('should handle :+1: and :-1: mutuality', () => {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      const $thumbsDownEmoji = $votesBlock.find('[data-name=thumbsdown]').parent();
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);

      expect($thumbsUpEmoji.hasClass('active')).toBe(true);
      expect($thumbsDownEmoji.hasClass('active')).toBe(false);
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsdown', true);

      expect($thumbsUpEmoji.hasClass('active')).toBe(false);
      expect($thumbsDownEmoji.hasClass('active')).toBe(true);
    });
  });

  describe('::removeEmoji', () => {
    it('should remove emoji', () => {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      awardsHandler.addAward($votesBlock, awardUrl, 'fire', false);

      expect($votesBlock.find('[data-name=fire]').length).toBe(1);
      awardsHandler.removeEmoji($votesBlock.find('[data-name=fire]').closest('button'));

      expect($votesBlock.find('[data-name=fire]').length).toBe(0);
    });
  });

  describe('::addYouToUserList', () => {
    it('should prepend "You" to the award tooltip', () => {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'sam, jerry, max, and andy');
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);

      expect($thumbsUpEmoji.attr('title')).toBe('You, sam, jerry, max, and andy');
    });

    it('handles the special case where "You" is not cleanly comma separated', () => {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'sam');
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);

      expect($thumbsUpEmoji.attr('title')).toBe('You and sam');
    });
  });

  describe('::removeYouToUserList', () => {
    it('removes "You" from the front of the tooltip', () => {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'You, sam, jerry, max, and andy');
      $thumbsUpEmoji.addClass('active');
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);

      expect($thumbsUpEmoji.attr('title')).toBe('sam, jerry, max, and andy');
    });

    it('handles the special case where "You" is not cleanly comma separated', () => {
      const awardUrl = awardsHandler.getAwardUrl();
      const $votesBlock = $('.js-awards-block').eq(0);
      const $thumbsUpEmoji = $votesBlock.find('[data-name=thumbsup]').parent();
      $thumbsUpEmoji.attr('data-title', 'You and sam');
      $thumbsUpEmoji.addClass('active');
      awardsHandler.addAward($votesBlock, awardUrl, 'thumbsup', false);

      expect($thumbsUpEmoji.attr('title')).toBe('sam');
    });
  });

  describe('::searchEmojis', () => {
    it('should filter the emoji', async () => {
      await openAndWaitForEmojiMenu();

      expect($('[data-name=angel]').is(':visible')).toBe(true);
      expect($('[data-name=anger]').is(':visible')).toBe(true);
      awardsHandler.searchEmojis('ali');

      expect($('[data-name=angel]').is(':visible')).toBe(false);
      expect($('[data-name=anger]').is(':visible')).toBe(false);
      expect($('[data-name=alien]').is(':visible')).toBe(true);
      expect($('.js-emoji-menu-search').val()).toBe('ali');
    });

    it('should clear the search when searching for nothing', async () => {
      await openAndWaitForEmojiMenu();

      awardsHandler.searchEmojis('ali');

      expect($('[data-name=angel]').is(':visible')).toBe(false);
      expect($('[data-name=anger]').is(':visible')).toBe(false);
      expect($('[data-name=alien]').is(':visible')).toBe(true);
      awardsHandler.searchEmojis('');

      expect($('[data-name=angel]').is(':visible')).toBe(true);
      expect($('[data-name=anger]').is(':visible')).toBe(true);
      expect($('[data-name=alien]').is(':visible')).toBe(true);
      expect($('.js-emoji-menu-search').val()).toBe('');
    });

    it('should filter by emoji description', async () => {
      await openAndWaitForEmojiMenu();

      awardsHandler.searchEmojis('baby');
      expect($('[data-name=angel]').is(':visible')).toBe(true);
    });

    it('should filter by emoji unicode value', async () => {
      await openAndWaitForEmojiMenu();

      awardsHandler.searchEmojis('👼');
      expect($('[data-name=angel]').is(':visible')).toBe(true);
    });
  });

  describe('emoji menu', () => {
    const emojiSelector = '[data-name="sunglasses"]';

    const openEmojiMenuAndAddEmoji = () => {
      return openAndWaitForEmojiMenu().then(() => {
        const $menu = $('.emoji-menu');
        const $block = $('.js-awards-block');
        const $emoji = $menu.find(`.emoji-menu-list:not(.frequent-emojis) ${emojiSelector}`);

        expect($emoji.length).toBe(1);
        expect($block.find(emojiSelector).length).toBe(0);
        $emoji.click();

        expect($menu.hasClass('.is-visible')).toBe(false);
        expect($block.find(emojiSelector).length).toBe(1);
      });
    };

    it('should add selected emoji to awards block', async () => {
      await openEmojiMenuAndAddEmoji();
    });

    it('should remove already selected emoji', async () => {
      await openEmojiMenuAndAddEmoji();

      $('.js-add-award').eq(0).click();
      const $block = $('.js-awards-block');
      const $emoji = $('.emoji-menu').find(
        `.emoji-menu-list:not(.frequent-emojis) ${emojiSelector}`,
      );
      $emoji.click();

      expect($block.find(emojiSelector).length).toBe(0);
    });
  });

  describe('frequently used emojis', () => {
    beforeEach(() => {
      // Clear it out
      Cookies.set('frequently_used_emojis', '');
    });

    it('shouldn\'t have any "Frequently used" heading if no frequently used emojis', async () => {
      await openAndWaitForEmojiMenu();

      const emojiMenu = document.querySelector('.emoji-menu');
      Array.prototype.forEach.call(emojiMenu.querySelectorAll('.emoji-menu-title'), (title) => {
        expect(title.textContent.trim().toLowerCase()).not.toBe('frequently used');
      });
    });

    it('should have any frequently used section when there are frequently used emojis', async () => {
      awardsHandler.addEmojiToFrequentlyUsedList('8ball');

      await openAndWaitForEmojiMenu();

      const emojiMenu = document.querySelector('.emoji-menu');
      const hasFrequentlyUsedHeading = Array.prototype.some.call(
        emojiMenu.querySelectorAll('.emoji-menu-title'),
        (title) => title.textContent.trim().toLowerCase() === 'frequently used',
      );

      expect(hasFrequentlyUsedHeading).toBe(true);
    });

    it('should disregard invalid frequently used emoji that are being attempted to be added', () => {
      awardsHandler.addEmojiToFrequentlyUsedList('8ball');
      awardsHandler.addEmojiToFrequentlyUsedList('invalid_emoji');
      awardsHandler.addEmojiToFrequentlyUsedList('grinning');

      expect(awardsHandler.getFrequentlyUsedEmojis()).toEqual(['8ball', 'grinning']);
    });

    it('should disregard invalid frequently used emoji already set in cookie', () => {
      Cookies.set('frequently_used_emojis', '8ball,invalid_emoji,grinning');

      expect(awardsHandler.getFrequentlyUsedEmojis()).toEqual(['8ball', 'grinning']);
    });
  });
});
