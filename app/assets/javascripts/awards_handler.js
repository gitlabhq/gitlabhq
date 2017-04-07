import Cookies from 'js-cookie';

import emojiMap from 'emojis/digests.json';
import emojiAliases from 'emojis/aliases.json';
import { glEmojiTag } from './behaviors/gl_emoji';
import isEmojiNameValid from './behaviors/gl_emoji/is_emoji_name_valid';

const animationEndEventString = 'animationend webkitAnimationEnd MSAnimationEnd oAnimationEnd';
const transitionEndEventString = 'transitionend webkitTransitionEnd oTransitionEnd MSTransitionEnd';
const requestAnimationFrame = window.requestAnimationFrame ||
  window.webkitRequestAnimationFrame ||
  window.mozRequestAnimationFrame ||
  window.setTimeout;

const FROM_SENTENCE_REGEX = /(?:, and | and |, )/; // For separating lists produced by ruby's Array#toSentence

let categoryMap = null;

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

function buildCategoryMap() {
  return Object.keys(emojiMap).reduce((currentCategoryMap, emojiNameKey) => {
    const emojiInfo = emojiMap[emojiNameKey];
    if (currentCategoryMap[emojiInfo.category]) {
      currentCategoryMap[emojiInfo.category].push(emojiNameKey);
    }

    return currentCategoryMap;
  }, {
    activity: [],
    people: [],
    nature: [],
    food: [],
    travel: [],
    objects: [],
    symbols: [],
    flags: [],
  });
}

function renderCategory(name, emojiList, opts = {}) {
  return `
    <h5 class="emoji-menu-title">
      ${name}
    </h5>
    <ul class="clearfix emoji-menu-list ${opts.menuListClass || ''}">
      ${emojiList.map(emojiName => `
        <li class="emoji-menu-list-item">
          <button class="emoji-menu-btn text-center js-emoji-btn" type="button">
            ${glEmojiTag(emojiName, {
              sprite: true,
            })}
          </button>
        </li>
      `).join('\n')}
    </ul>
  `;
}

function AwardsHandler() {
  this.eventListeners = [];
  this.aliases = emojiAliases;
  // If the user shows intent let's pre-build the menu
  this.registerEventListener('one', $(document), 'mouseenter focus', '.js-add-award', 'mouseenter focus', () => {
    const $menu = $('.emoji-menu');
    if ($menu.length === 0) {
      requestAnimationFrame(() => {
        this.createEmojiMenu();
      });
    }
    // Prebuild the categoryMap
    categoryMap = categoryMap || buildCategoryMap();
  });
  this.registerEventListener('on', $(document), 'click', '.js-add-award', (e) => {
    e.stopPropagation();
    e.preventDefault();
    this.showEmojiMenu($(e.currentTarget));
  });

  this.registerEventListener('on', $('html'), 'click', (e) => {
    const $target = $(e.target);
    if (!$target.closest('.emoji-menu-content').length) {
      $('.js-awards-block.current').removeClass('current');
    }
    if (!$target.closest('.emoji-menu').length) {
      if ($('.emoji-menu').is(':visible')) {
        $('.js-add-award.is-active').removeClass('is-active');
        $('.emoji-menu').removeClass('is-visible');
      }
    }
  });
  this.registerEventListener('on', $(document), 'click', '.js-emoji-btn', (e) => {
    e.preventDefault();
    const $target = $(e.currentTarget);
    const $glEmojiElement = $target.find('gl-emoji');
    const $spriteIconElement = $target.find('.icon');
    const emoji = ($glEmojiElement.length ? $glEmojiElement : $spriteIconElement).data('name');

    $target.closest('.js-awards-block').addClass('current');
    this.addAward(this.getVotesBlock(), this.getAwardUrl(), emoji);
  });
}

AwardsHandler.prototype.registerEventListener = function registerEventListener(method = 'on', element, ...args) {
  element[method].call(element, ...args);
  this.eventListeners.push({
    element,
    args,
  });
};

AwardsHandler.prototype.showEmojiMenu = function showEmojiMenu($addBtn) {
  if ($addBtn.hasClass('js-note-emoji')) {
    $addBtn.closest('.note').find('.js-awards-block').addClass('current');
  } else {
    $addBtn.closest('.js-awards-block').addClass('current');
  }

  const $menu = $('.emoji-menu');
  if ($menu.length) {
    if ($menu.is('.is-visible')) {
      $addBtn.removeClass('is-active');
      $menu.removeClass('is-visible');
      $('.js-emoji-menu-search').blur();
    } else {
      $addBtn.addClass('is-active');
      this.positionMenu($menu, $addBtn);
      $menu.addClass('is-visible');
      $('.js-emoji-menu-search').focus();
    }
  } else {
    $addBtn.addClass('is-loading is-active');
    this.createEmojiMenu(() => {
      const $createdMenu = $('.emoji-menu');
      $addBtn.removeClass('is-loading');
      this.positionMenu($createdMenu, $addBtn);
      return setTimeout(() => {
        $createdMenu.addClass('is-visible');
        $('.js-emoji-menu-search').focus();
      }, 200);
    });
  }
};

// Create the emoji menu with the first category of emojis.
// Then render the remaining categories of emojis one by one to avoid jank.
AwardsHandler.prototype.createEmojiMenu = function createEmojiMenu(callback) {
  if (this.isCreatingEmojiMenu) {
    return;
  }
  this.isCreatingEmojiMenu = true;

  // Render the first category
  categoryMap = categoryMap || buildCategoryMap();
  const categoryNameKey = Object.keys(categoryMap)[0];
  const emojisInCategory = categoryMap[categoryNameKey];
  const firstCategory = renderCategory(categoryLabelMap[categoryNameKey], emojisInCategory);

  // Render the frequently used
  const frequentlyUsedEmojis = this.getFrequentlyUsedEmojis();
  let frequentlyUsedCatgegory = '';
  if (frequentlyUsedEmojis.length > 0) {
    frequentlyUsedCatgegory = renderCategory('Frequently used', frequentlyUsedEmojis, {
      menuListClass: 'frequent-emojis',
    });
  }

  const emojiMenuMarkup = `
    <div class="emoji-menu">
      <input type="text" name="emoji-menu-search" value="" class="js-emoji-menu-search emoji-search search-input form-control" placeholder="Search emoji" />

      <div class="emoji-menu-content">
        ${frequentlyUsedCatgegory}
        ${firstCategory}
      </div>
    </div>
  `;

  document.body.insertAdjacentHTML('beforeend', emojiMenuMarkup);

  this.addRemainingEmojiMenuCategories();
  this.setupSearch();
  if (callback) {
    callback();
  }
};

AwardsHandler
  .prototype
  .addRemainingEmojiMenuCategories = function addRemainingEmojiMenuCategories() {
    if (this.isAddingRemainingEmojiMenuCategories) {
      return;
    }
    this.isAddingRemainingEmojiMenuCategories = true;

    categoryMap = categoryMap || buildCategoryMap();

    // Avoid the jank and render the remaining categories separately
    // This will take more time, but makes UI more responsive
    const menu = document.querySelector('.emoji-menu');
    const emojiContentElement = menu.querySelector('.emoji-menu-content');
    const remainingCategories = Object.keys(categoryMap).slice(1);
    const allCategoriesAddedPromise = remainingCategories.reduce(
      (promiseChain, categoryNameKey) =>
        promiseChain.then(() =>
          new Promise((resolve) => {
            const emojisInCategory = categoryMap[categoryNameKey];
            const categoryMarkup = renderCategory(
              categoryLabelMap[categoryNameKey],
              emojisInCategory,
            );
            requestAnimationFrame(() => {
              emojiContentElement.insertAdjacentHTML('beforeend', categoryMarkup);
              resolve();
            });
          }),
      ),
      Promise.resolve(),
    );

    allCategoriesAddedPromise.then(() => {
      // Used for tests
      // We check for the menu in case it was destroyed in the meantime
      if (menu) {
        menu.dispatchEvent(new CustomEvent('build-emoji-menu-finish'));
      }
    });
  };

AwardsHandler.prototype.positionMenu = function positionMenu($menu, $addBtn) {
  const position = $addBtn.data('position');
  // The menu could potentially be off-screen or in a hidden overflow element
  // So we position the element absolute in the body
  const css = {
    top: `${$addBtn.offset().top + $addBtn.outerHeight()}px`,
  };
  if (position === 'right') {
    css.left = `${($addBtn.offset().left - $menu.outerWidth()) + 20}px`;
    $menu.addClass('is-aligned-right');
  } else {
    css.left = `${$addBtn.offset().left}px`;
    $menu.removeClass('is-aligned-right');
  }
  return $menu.css(css);
};

AwardsHandler.prototype.addAward = function addAward(
  votesBlock,
  awardUrl,
  emoji,
  checkMutuality,
  callback,
) {
  const normalizedEmoji = this.normalizeEmojiName(emoji);
  this.postEmoji(awardUrl, normalizedEmoji, () => {
    this.addAwardToEmojiBar(votesBlock, normalizedEmoji, checkMutuality);
    return typeof callback === 'function' ? callback() : undefined;
  });
  $('.emoji-menu').removeClass('is-visible');
  $('.js-add-award.is-active').removeClass('is-active');
};

AwardsHandler.prototype.addAwardToEmojiBar = function addAwardToEmojiBar(
  votesBlock,
  emoji,
  checkForMutuality,
) {
  if (checkForMutuality || checkForMutuality === null) {
    this.checkMutuality(votesBlock, emoji);
  }
  this.addEmojiToFrequentlyUsedList(emoji);
  const normalizedEmoji = this.normalizeEmojiName(emoji);
  const $emojiButton = this.findEmojiIcon(votesBlock, normalizedEmoji).parent();
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
};

AwardsHandler.prototype.getVotesBlock = function getVotesBlock() {
  const currentBlock = $('.js-awards-block.current');
  let resultantVotesBlock = currentBlock;
  if (currentBlock.length === 0) {
    resultantVotesBlock = $('.js-awards-block').eq(0);
  }

  return resultantVotesBlock;
};

AwardsHandler.prototype.getAwardUrl = function getAwardUrl() {
  return this.getVotesBlock().data('award-url');
};

AwardsHandler.prototype.checkMutuality = function checkMutuality(votesBlock, emoji) {
  const awardUrl = this.getAwardUrl();
  if (emoji === 'thumbsup' || emoji === 'thumbsdown') {
    const mutualVote = emoji === 'thumbsup' ? 'thumbsdown' : 'thumbsup';
    const $emojiButton = votesBlock.find(`[data-name="${mutualVote}"]`).parent();
    const isAlreadyVoted = $emojiButton.hasClass('active');
    if (isAlreadyVoted) {
      this.addAward(votesBlock, awardUrl, mutualVote, false);
    }
  }
};

AwardsHandler.prototype.isActive = function isActive($emojiButton) {
  return $emojiButton.hasClass('active');
};

AwardsHandler.prototype.decrementCounter = function decrementCounter($emojiButton, emoji) {
  const counter = $('.js-counter', $emojiButton);
  const counterNumber = parseInt(counter.text(), 10);
  if (counterNumber > 1) {
    counter.text(counterNumber - 1);
    this.removeYouFromUserList($emojiButton);
  } else if (emoji === 'thumbsup' || emoji === 'thumbsdown') {
    $emojiButton.tooltip('destroy');
    counter.text('0');
    this.removeYouFromUserList($emojiButton);
    if ($emojiButton.parents('.note').length) {
      this.removeEmoji($emojiButton);
    }
  } else {
    this.removeEmoji($emojiButton);
  }
  return $emojiButton.removeClass('active');
};

AwardsHandler.prototype.removeEmoji = function removeEmoji($emojiButton) {
  $emojiButton.tooltip('destroy');
  $emojiButton.remove();
  const $votesBlock = this.getVotesBlock();
  if ($votesBlock.find('.js-emoji-btn').length === 0) {
    $votesBlock.addClass('hidden');
  }
};

AwardsHandler.prototype.getAwardTooltip = function getAwardTooltip($awardBlock) {
  return $awardBlock.attr('data-original-title') || $awardBlock.attr('data-title') || '';
};

AwardsHandler.prototype.toSentence = function toSentence(list) {
  let sentence;
  if (list.length <= 2) {
    sentence = list.join(' and ');
  } else {
    sentence = `${list.slice(0, -1).join(', ')}, and ${list[list.length - 1]}`;
  }

  return sentence;
};

AwardsHandler.prototype.removeYouFromUserList = function removeYouFromUserList($emojiButton) {
  const awardBlock = $emojiButton;
  const originalTitle = this.getAwardTooltip(awardBlock);
  const authors = originalTitle.split(FROM_SENTENCE_REGEX);
  authors.splice(authors.indexOf('You'), 1);
  return awardBlock
    .closest('.js-emoji-btn')
    .removeData('title')
    .removeAttr('data-title')
    .removeAttr('data-original-title')
    .attr('title', this.toSentence(authors))
    .tooltip('fixTitle');
};

AwardsHandler.prototype.addYouToUserList = function addYouToUserList(votesBlock, emoji) {
  const awardBlock = this.findEmojiIcon(votesBlock, emoji).parent();
  const origTitle = this.getAwardTooltip(awardBlock);
  let users = [];
  if (origTitle) {
    users = origTitle.trim().split(FROM_SENTENCE_REGEX);
  }
  users.unshift('You');
  return awardBlock
    .attr('title', this.toSentence(users))
    .tooltip('fixTitle');
};

AwardsHandler
  .prototype
  .createAwardButtonForVotesBlock = function createAwardButtonForVotesBlock(votesBlock, emojiName) {
    const buttonHtml = `
      <button class="btn award-control js-emoji-btn has-tooltip active" title="You" data-placement="bottom">
        ${glEmojiTag(emojiName)}
        <span class="award-control-text js-counter">1</span>
      </button>
    `;
    const $emojiButton = $(buttonHtml);
    $emojiButton.insertBefore(votesBlock.find('.js-award-holder')).find('.emoji-icon').data('name', emojiName);
    this.animateEmoji($emojiButton);
    $('.award-control').tooltip();
    votesBlock.removeClass('current');
  };

AwardsHandler.prototype.animateEmoji = function animateEmoji($emoji) {
  const className = 'pulse animated once short';
  $emoji.addClass(className);

  this.registerEventListener('on', $emoji, animationEndEventString, (e) => {
    $(e.currentTarget).removeClass(className);
  });
};

AwardsHandler.prototype.createEmoji = function createEmoji(votesBlock, emoji) {
  if ($('.emoji-menu').length) {
    this.createAwardButtonForVotesBlock(votesBlock, emoji);
  }
  this.createEmojiMenu(() => {
    this.createAwardButtonForVotesBlock(votesBlock, emoji);
  });
};

AwardsHandler.prototype.postEmoji = function postEmoji(awardUrl, emoji, callback) {
  return $.post(awardUrl, {
    name: emoji,
  }, (data) => {
    if (data.ok) {
      callback();
    }
  });
};

AwardsHandler.prototype.findEmojiIcon = function findEmojiIcon(votesBlock, emoji) {
  return votesBlock.find(`.js-emoji-btn [data-name="${emoji}"]`);
};

AwardsHandler.prototype.scrollToAwards = function scrollToAwards() {
  const options = {
    scrollTop: $('.awards').offset().top - 110,
  };
  return $('body, html').animate(options, 200);
};

AwardsHandler.prototype.normalizeEmojiName = function normalizeEmojiName(emoji) {
  return Object.prototype.hasOwnProperty.call(this.aliases, emoji) ? this.aliases[emoji] : emoji;
};

AwardsHandler
  .prototype
  .addEmojiToFrequentlyUsedList = function addEmojiToFrequentlyUsedList(emoji) {
    if (isEmojiNameValid(emoji)) {
      this.frequentlyUsedEmojis = _.uniq(this.getFrequentlyUsedEmojis().concat(emoji));
      Cookies.set('frequently_used_emojis', this.frequentlyUsedEmojis.join(','), { expires: 365 });
    }
  };

AwardsHandler.prototype.getFrequentlyUsedEmojis = function getFrequentlyUsedEmojis() {
  return this.frequentlyUsedEmojis || (() => {
    const frequentlyUsedEmojis = _.uniq((Cookies.get('frequently_used_emojis') || '').split(','));
    this.frequentlyUsedEmojis = frequentlyUsedEmojis.filter(
      inputName => isEmojiNameValid(inputName),
    );

    return this.frequentlyUsedEmojis;
  })();
};

AwardsHandler.prototype.setupSearch = function setupSearch() {
  const $search = $('.js-emoji-menu-search');

  this.registerEventListener('on', $search, 'input', (e) => {
    const term = $(e.target).val().trim();
    this.searchEmojis(term);
  });

  const $menu = $('.emoji-menu');
  this.registerEventListener('on', $menu, transitionEndEventString, (e) => {
    if (e.target === e.currentTarget) {
      // Clear the search
      this.searchEmojis('');
    }
  });
};

AwardsHandler.prototype.searchEmojis = function searchEmojis(term) {
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
};

AwardsHandler.prototype.findMatchingEmojiElements = function findMatchingEmojiElements(term) {
  const safeTerm = term.toLowerCase();

  const namesMatchingAlias = [];
  Object.keys(emojiAliases).forEach((alias) => {
    if (alias.indexOf(safeTerm) >= 0) {
      namesMatchingAlias.push(emojiAliases[alias]);
    }
  });
  const $matchingElements = namesMatchingAlias.concat(safeTerm)
    .reduce(
      ($result, searchTerm) =>
        $result.add($(`.emoji-menu-list:not(.frequent-emojis) [data-name*="${searchTerm}"]`)),
      $([]),
    );
  return $matchingElements.closest('li').clone();
};

AwardsHandler.prototype.destroy = function destroy() {
  this.eventListeners.forEach((entry) => {
    entry.element.off.call(entry.element, ...entry.args);
  });
  $('.emoji-menu').remove();
};

export default AwardsHandler;
