/* eslint-disable class-methods-use-this, @gitlab/require-i18n-strings */

import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import $ from 'jquery';
import { uniq, escape } from 'lodash';
import { getEmojiScoreWithIntent } from '~/emoji/utils';
import { scrollToElement } from '~/lib/utils/common_utils';
import * as Emoji from '~/emoji';
import { dispose, fixTitle } from '~/tooltips';
import { createAlert } from '~/alert';
import {
  EMOJI_THUMBS_UP,
  EMOJI_THUMBS_DOWN,
  FREQUENTLY_USED_EMOJIS_STORAGE_KEY,
} from '~/emoji/constants';
import axios from './lib/utils/axios_utils';
import { isInVueNoteablePage } from './lib/utils/dom_utils';
import { __ } from './locale';

const animationEndEventString = 'animationend webkitAnimationEnd MSAnimationEnd oAnimationEnd';
const transitionEndEventString = 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd';

const FROM_SENTENCE_REGEX = /(?:, and | and |, )/; // For separating lists produced by ruby's Array#toSentence

const categoryLabelMap = {
  activity: 'Activity',
  people: 'People',
  nature: 'Nature',
  food: 'Food',
  travel: 'Travel',
  objects: 'Objects',
  symbols: 'Symbols',
  flags: 'Flags',
};

const IS_VISIBLE = 'is-visible';
const IS_RENDERED = 'is-rendered';

export class AwardsHandler {
  constructor(emoji) {
    this.emoji = emoji;
    this.eventListeners = [];
    this.toggleButtonSelector = '.js-add-award';
    this.menuClass = 'js-award-emoji-menu';
  }

  bindEvents() {
    const $parentEl = this.targetContainerEl ? $(this.targetContainerEl) : $(document);
    // If the user shows intent let's pre-build the menu
    this.registerEventListener(
      'one',
      $parentEl,
      'mouseenter focus',
      this.toggleButtonSelector,
      'mouseenter focus',
      () => {
        const $menu = $(`.${this.menuClass}`);
        if ($menu.length === 0) {
          requestAnimationFrame(() => {
            this.createEmojiMenu();
          });
        }
      },
    );
    this.registerEventListener('on', $parentEl, 'click', this.toggleButtonSelector, (e) => {
      e.stopPropagation();
      e.preventDefault();
      this.showEmojiMenu($(e.currentTarget));
    });

    this.registerEventListener('on', $('html'), 'click', (e) => {
      const $target = $(e.target);
      if (!$target.closest(`.${this.menuClass}`).length) {
        $('.js-awards-block.current').removeClass('current');
        if ($(`.${this.menuClass}`).is(':visible')) {
          $(`${this.toggleButtonSelector}.is-active`).removeClass('is-active');
          this.hideMenuElement($(`.${this.menuClass}`));
        }
      }
    });

    const emojiButtonSelector = `.js-awards-block .js-emoji-btn, .${this.menuClass} .js-emoji-btn`;
    this.registerEventListener('on', $parentEl, 'click', emojiButtonSelector, (e) => {
      e.preventDefault();
      const $target = $(e.currentTarget);
      const $glEmojiElement = $target.find('gl-emoji');
      const $spriteIconElement = $target.find('.icon');
      const emojiName = ($glEmojiElement.length ? $glEmojiElement : $spriteIconElement).data(
        'name',
      );

      $target.closest('.js-awards-block').addClass('current');
      this.addAward(this.getVotesBlock(), this.getAwardUrl(), emojiName);
    });
  }

  registerEventListener(method = 'on', element, ...args) {
    element[method].call(element, ...args);
    this.eventListeners.push({
      element,
      args,
    });
  }

  showEmojiMenu($addBtn) {
    if ($addBtn.hasClass('js-note-emoji')) {
      $addBtn.closest('.note').find('.js-awards-block').addClass('current');
    } else {
      $addBtn.closest('.js-awards-block').addClass('current');
    }

    const $menu = $(`.${this.menuClass}`);
    if ($menu.length) {
      if ($menu.is('.is-visible')) {
        $addBtn.removeClass('is-active');
        this.hideMenuElement($menu);
        $('.js-emoji-menu-search').blur();
      } else {
        $addBtn.addClass('is-active');
        this.positionMenu($menu, $addBtn);
        this.showMenuElement($menu);
        $('.js-emoji-menu-search').focus();
      }
    } else {
      $addBtn.addClass('is-loading is-active');
      this.createEmojiMenu(() => {
        const $createdMenu = $(`.${this.menuClass}`);
        $addBtn.removeClass('is-loading');
        this.positionMenu($createdMenu, $addBtn);
        return setTimeout(() => {
          this.showMenuElement($createdMenu);
          $('.js-emoji-menu-search').focus();
        }, 200);
      });
    }
  }

  // Create the emoji menu with the first category of emojis.
  // Then render the remaining categories of emojis one by one to avoid jank.
  createEmojiMenu(callback) {
    if (this.isCreatingEmojiMenu) {
      return;
    }
    this.isCreatingEmojiMenu = true;

    // Render the first category
    const categoryMap = this.emoji.getEmojiCategoryMap();
    const categoryNameKey = Object.keys(categoryMap)[0];
    const emojisInCategory = categoryMap[categoryNameKey];
    const firstCategory = this.renderCategory(categoryLabelMap[categoryNameKey], emojisInCategory);

    // Render the frequently used
    const frequentlyUsedEmojis = this.getFrequentlyUsedEmojis();
    let frequentlyUsedCatgegory = '';
    if (frequentlyUsedEmojis.length > 0) {
      frequentlyUsedCatgegory = this.renderCategory('Frequently used', frequentlyUsedEmojis, {
        frequentEmojis: true,
      });
    }

    const emojiMenuMarkup = `
      <div class="emoji-menu ${this.menuClass}">
        <input type="text" name="emoji-menu-search" value="" class="js-emoji-menu-search emoji-search search-input form-control" placeholder="Search emoji" />

        <div class="emoji-menu-content">
          ${frequentlyUsedCatgegory}
          ${firstCategory}
        </div>
      </div>
    `;

    const targetEl = this.targetContainerEl ? this.targetContainerEl : document.body;
    // eslint-disable-next-line no-unsanitized/method
    targetEl.insertAdjacentHTML('beforeend', emojiMenuMarkup);

    this.addRemainingEmojiMenuCategories();
    this.setupSearch();
    if (callback) {
      callback();
    }
  }

  addRemainingEmojiMenuCategories() {
    if (this.isAddingRemainingEmojiMenuCategories) {
      return;
    }
    this.isAddingRemainingEmojiMenuCategories = true;

    const categoryMap = this.emoji.getEmojiCategoryMap();

    // Avoid the jank and render the remaining categories separately
    // This will take more time, but makes UI more responsive
    const menu = document.querySelector(`.${this.menuClass}`);
    const emojiContentElement = menu.querySelector('.emoji-menu-content');
    const remainingCategories = Object.keys(categoryMap).slice(1);
    const allCategoriesAddedPromise = remainingCategories.reduce(
      (promiseChain, categoryNameKey) =>
        promiseChain.then(
          () =>
            new Promise((resolve) => {
              const emojisInCategory = categoryMap[categoryNameKey];
              const categoryMarkup = this.renderCategory(
                categoryLabelMap[categoryNameKey],
                emojisInCategory,
              );
              requestAnimationFrame(() => {
                // eslint-disable-next-line no-unsanitized/method
                emojiContentElement.insertAdjacentHTML('beforeend', categoryMarkup);
                resolve();
              });
            }),
        ),
      Promise.resolve(),
    );

    allCategoriesAddedPromise
      .then(() => {
        // Used for tests
        // We check for the menu in case it was destroyed in the meantime
        if (menu) {
          menu.dispatchEvent(new CustomEvent('build-emoji-menu-finish'));
        }
      })
      .catch((err) => {
        emojiContentElement.insertAdjacentHTML(
          'beforeend',
          '<p>We encountered an error while adding the remaining categories</p>',
        );
        throw new Error(`Error occurred in addRemainingEmojiMenuCategories: ${err.message}`);
      });
  }

  renderCategory(name, emojiList, opts = {}) {
    return `
      <h5 class="emoji-menu-title">
        ${escape(name)}
      </h5>
      <ul class="clearfix emoji-menu-list ${opts.frequentEmojis ? 'frequent-emojis' : ''}">
        ${emojiList
          .map(
            (emojiName) => `
          <li class="emoji-menu-list-item">
            <button class="emoji-menu-btn text-center js-emoji-btn" type="button">
              ${this.emoji.glEmojiTag(emojiName, {
                sprite: true,
              })}
            </button>
          </li>
        `,
          )
          .join('\n')}
      </ul>
    `;
  }

  positionMenu($menu, $addBtn) {
    if (this.targetContainerEl) {
      return $menu.css({
        top: `${$addBtn.outerHeight()}px`,
      });
    }

    const position = $addBtn.data('position');
    // The menu could potentially be off-screen or in a hidden overflow element
    // So we position the element absolute in the body
    const css = {
      top: `${$addBtn.offset().top + $addBtn.outerHeight()}px`,
    };
    // for xs screen we position the element on center
    if (bp.getBreakpointSize() === 'xs' || bp.getBreakpointSize() === 'sm') {
      css.left = '5%';
    } else if (position === 'right') {
      css.left = `${$addBtn.offset().left - $menu.outerWidth() + 20}px`;
      $menu.addClass('is-aligned-right');
    } else {
      css.left = `${$addBtn.offset().left}px`;
      $menu.removeClass('is-aligned-right');
    }
    return $menu.css(css);
  }

  // eslint-disable-next-line max-params
  addAward(votesBlock, awardUrl, emoji, callback) {
    const isMainAwardsBlock = votesBlock.closest('.js-noteable-awards').length;

    if (isInVueNoteablePage() && !isMainAwardsBlock) {
      const id = votesBlock.attr('id').replace('note_', '');

      this.hideMenuElement($(`.${this.menuClass}`));

      $(`${this.toggleButtonSelector}.is-active`).removeClass('is-active');
      const toggleAwardEvent = new CustomEvent('toggleAward', {
        detail: {
          awardName: emoji,
          noteId: id,
        },
      });

      document.querySelector('.js-vue-notes-event').dispatchEvent(toggleAwardEvent);
    }

    const normalizedEmoji = this.emoji.normalizeEmojiName(emoji);
    const $emojiButton = this.findEmojiIcon(votesBlock, normalizedEmoji).closest('button');

    this.postEmoji($emojiButton, awardUrl, normalizedEmoji, () => {
      this.addAwardToEmojiBar(votesBlock, normalizedEmoji);
      return typeof callback === 'function' ? callback() : undefined;
    });

    this.hideMenuElement($(`.${this.menuClass}`));

    return $(`${this.toggleButtonSelector}.is-active`).removeClass('is-active');
  }

  addAwardToEmojiBar(votesBlock, emoji) {
    this.addEmojiToFrequentlyUsedList(emoji);
    const normalizedEmoji = this.emoji.normalizeEmojiName(emoji);
    const $emojiButton = this.findEmojiIcon(votesBlock, normalizedEmoji).closest('button');
    if ($emojiButton.length > 0) {
      if (this.isActive($emojiButton)) {
        this.decrementCounter($emojiButton, normalizedEmoji);
      } else {
        const counter = $emojiButton.find('.js-counter');
        counter.text(parseInt(counter.text(), 10) + 1);
        $emojiButton.addClass('active');
        this.addYouToUserList(votesBlock, normalizedEmoji);
        this.animateEmoji($emojiButton);
      }
    } else {
      votesBlock.removeClass('hidden');
      this.createEmoji(votesBlock, normalizedEmoji);
    }
  }

  getVotesBlock() {
    if (isInVueNoteablePage()) {
      const $el = $(`${this.toggleButtonSelector}.is-active`).closest('.note.timeline-entry');

      if ($el.length) {
        return $el;
      }
    }

    const currentBlock = $('.js-awards-block.current');
    let resultantVotesBlock = currentBlock;
    if (currentBlock.length === 0) {
      resultantVotesBlock = $('.js-awards-block').eq(0);
    }

    return resultantVotesBlock;
  }

  getAwardUrl() {
    return this.getVotesBlock().data('awardUrl');
  }

  isActive($emojiButton) {
    return $emojiButton.hasClass('active');
  }

  decrementCounter($emojiButton, emoji) {
    const counter = $('.js-counter', $emojiButton);
    const counterNumber = parseInt(counter.text(), 10);
    if (counterNumber > 1) {
      counter.text(counterNumber - 1);
      this.removeYouFromUserList($emojiButton);
    } else if (emoji === EMOJI_THUMBS_UP || emoji === EMOJI_THUMBS_DOWN) {
      dispose($emojiButton);
      counter.text('0');
      this.removeYouFromUserList($emojiButton);
      if ($emojiButton.parents('.note').length) {
        this.removeEmoji($emojiButton);
      }
    } else {
      this.removeEmoji($emojiButton);
    }
    return $emojiButton.removeClass('active');
  }

  removeEmoji($emojiButton) {
    dispose($emojiButton);

    $emojiButton.remove();
    const $votesBlock = this.getVotesBlock();
    if ($votesBlock.find('.js-emoji-btn').length === 0) {
      $votesBlock.addClass('hidden');
    }
  }

  getAwardTooltip($awardBlock) {
    return $awardBlock.attr('data-original-title') || $awardBlock.attr('data-title') || '';
  }

  toSentence(list) {
    let sentence;
    if (list.length <= 2) {
      sentence = list.join(' and ');
    } else {
      sentence = `${list.slice(0, -1).join(', ')}, and ${list[list.length - 1]}`;
    }

    return sentence;
  }

  removeYouFromUserList($emojiButton) {
    const awardBlock = $emojiButton;
    const originalTitle = this.getAwardTooltip(awardBlock);
    const authors = originalTitle.split(FROM_SENTENCE_REGEX);
    authors.splice(authors.indexOf('You'), 1);

    awardBlock
      .closest('.js-emoji-btn')
      .removeData('title')
      .removeAttr('data-title')
      .removeAttr('data-original-title')
      .attr('title', this.toSentence(authors));

    fixTitle(awardBlock);

    return awardBlock;
  }

  addYouToUserList(votesBlock, emoji) {
    const awardBlock = this.findEmojiIcon(votesBlock, emoji).closest('button');
    const origTitle = this.getAwardTooltip(awardBlock);
    let users = [];
    if (origTitle) {
      users = origTitle.trim().split(FROM_SENTENCE_REGEX);
    }
    users.unshift('You');

    awardBlock.attr('title', this.toSentence(users));

    fixTitle(awardBlock);

    return awardBlock;
  }

  createAwardButtonForVotesBlock(votesBlock, emojiName) {
    const buttonHtml = `
      <button class="gl-button btn btn-default award-control js-emoji-btn has-tooltip active" title="You">
        ${this.emoji.glEmojiTag(emojiName)}
        <span class="award-control-text js-counter">1</span>
      </button>
    `;
    const $emojiButton = $(buttonHtml);
    $emojiButton
      .insertBefore(votesBlock.find('.js-award-holder'))
      .find('.emoji-icon')
      .data('name', emojiName);
    this.animateEmoji($emojiButton);

    votesBlock.removeClass('current');
  }

  animateEmoji($emoji) {
    const className = 'pulse animated once short';
    $emoji.addClass(className);

    this.registerEventListener('on', $emoji, animationEndEventString, (e) => {
      $(e.currentTarget).removeClass(className);
    });
  }

  createEmoji(votesBlock, emoji) {
    if ($(`.${this.menuClass}`).length) {
      this.createAwardButtonForVotesBlock(votesBlock, emoji);
    }
    this.createEmojiMenu(() => {
      this.createAwardButtonForVotesBlock(votesBlock, emoji);
    });
  }

  // eslint-disable-next-line max-params
  postEmoji($emojiButton, awardUrl, emoji, callback) {
    axios
      .post(awardUrl, {
        name: emoji,
      })
      .then(({ data }) => {
        if (data.ok) {
          callback();
        }
      })
      .catch(() =>
        createAlert({
          message: __('Something went wrong on our end.'),
        }),
      );
  }

  findEmojiIcon(votesBlock, emoji) {
    return votesBlock.find(`.js-emoji-btn [data-name="${emoji}"]`);
  }

  scrollToAwards() {
    scrollToElement('.awards', { offset: -110 });
  }

  addEmojiToFrequentlyUsedList(emoji) {
    if (this.emoji.isEmojiNameValid(emoji)) {
      this.frequentlyUsedEmojis = uniq(this.getFrequentlyUsedEmojis().concat(emoji));
      localStorage.setItem(FREQUENTLY_USED_EMOJIS_STORAGE_KEY, this.frequentlyUsedEmojis.join(','));
    }
  }

  getFrequentlyUsedEmojis() {
    return (
      this.frequentlyUsedEmojis ||
      (() => {
        const frequentlyUsedEmojis = uniq(
          (localStorage.getItem(FREQUENTLY_USED_EMOJIS_STORAGE_KEY) || '').split(','),
        );
        this.frequentlyUsedEmojis = frequentlyUsedEmojis.filter((inputName) =>
          this.emoji.isEmojiNameValid(inputName),
        );

        return this.frequentlyUsedEmojis;
      })()
    );
  }

  setupSearch() {
    const $search = $('.js-emoji-menu-search');

    this.registerEventListener('on', $search, 'input', (e) => {
      const term = $(e.target).val().trim();
      this.searchEmojis(term);
    });

    const $menu = $(`.${this.menuClass}`);
    this.registerEventListener('on', $menu, transitionEndEventString, (e) => {
      if (e.target === e.currentTarget) {
        // Clear the search
        this.searchEmojis('');
      }
    });
  }

  searchEmojis(term) {
    const $search = $('.js-emoji-menu-search');
    $search.val(term);

    // Clean previous search results
    $('ul.emoji-menu-search, h5.emoji-search-title').remove();
    if (term.length > 0) {
      // Generate a search result block
      const h5 = $('<h5 class="emoji-search-title"/>').text('Search results');
      const foundEmojis = this.findMatchingEmojiElements(term).show();
      const ul = $('<ul>').addClass('emoji-menu-list emoji-menu-search').append(foundEmojis);
      $('.emoji-menu-content ul, .emoji-menu-content h5').hide();
      $('.emoji-menu-content').append(h5).append(ul);
    } else {
      $('.emoji-menu-content').children().show();
    }
  }

  getEmojiScore(emojis, value) {
    const elem = $(value).find('[data-name]').get(0);
    const emoji = emojis.filter((x) => x.emoji.name === elem.dataset.name)[0];
    elem.dataset.score = emoji.score;

    return emoji.score;
  }

  sortEmojiElements(emojis, $elements) {
    const scores = new WeakMap();

    return $elements.sort((a, b) => {
      let aScore = scores.get(a);
      let bScore = scores.get(b);

      if (!aScore) {
        aScore = this.getEmojiScore(emojis, a);
        scores.set(a, aScore);
      }

      if (!bScore) {
        bScore = this.getEmojiScore(emojis, b);
        scores.set(b, bScore);
      }

      return aScore - bScore;
    });
  }

  findMatchingEmojiElements(query) {
    const matchingEmoji = this.emoji
      .searchEmoji(query)
      .map((x) => ({ ...x, score: getEmojiScoreWithIntent(x.emoji.name, x.score) }));
    const matchingEmojiNames = matchingEmoji.map((x) => x.emoji.name);
    const $emojiElements = $('.emoji-menu-list:not(.frequent-emojis) [data-name]');
    const $matchingElements = $emojiElements.filter(
      (i, elm) => matchingEmojiNames.indexOf(elm.dataset.name) >= 0,
    );
    return this.sortEmojiElements(matchingEmoji, $matchingElements.closest('li').clone());
  }

  /* showMenuElement and hideMenuElement are performance optimizations. We use
   * opacity to show/hide the emoji menu, because we can animate it. But opacity
   * leaves hidden elements in the render tree, which is unacceptable given the number
   * of emoji elements in the emoji menu (5k+). To get the best of both worlds, we separately
   * apply IS_RENDERED to add/remove the menu from the render tree and IS_VISIBLE to animate
   * the menu being opened and closed. */

  showMenuElement($emojiMenu) {
    $emojiMenu.addClass(IS_RENDERED);

    // enqueues animation as a microtask, so it begins ASAP once IS_RENDERED added
    return Promise.resolve().then(() => $emojiMenu.addClass(IS_VISIBLE));
  }

  hideMenuElement($emojiMenu) {
    $emojiMenu.on(transitionEndEventString, (e) => {
      if (e.currentTarget === e.target) {
        // eslint-disable-next-line @gitlab/no-global-event-off
        $emojiMenu.removeClass(IS_RENDERED).off(transitionEndEventString);
      }
    });

    $emojiMenu.removeClass(IS_VISIBLE);
  }

  destroy() {
    this.eventListeners.forEach((entry) => {
      entry.element.off.call(entry.element, ...entry.args);
    });
    $(`.${this.menuClass}`).remove();
  }
}

let awardsHandlerPromise = null;
export default function loadAwardsHandler(reload = false) {
  if (!awardsHandlerPromise || reload) {
    awardsHandlerPromise = Emoji.initEmojiMap().then(() => {
      const awardsHandler = new AwardsHandler(Emoji);
      awardsHandler.bindEvents();
      return awardsHandler;
    });
  }
  return awardsHandlerPromise;
}
