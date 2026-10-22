import { BOARD_CARD_LINK_CLASS, BOARD_CARD_LIST_CLASS } from './constants';

export const FOCUS_PREVIOUS = -1;
export const FOCUS_NEXT = 1;

const LIST_SELECTOR = `.${BOARD_CARD_LIST_CLASS}`;
const LINK_SELECTOR = `.${BOARD_CARD_LINK_CLASS}`;

const findLinks = (list) => [...list.querySelectorAll(LINK_SELECTOR)];

export function focusCardInColumn(link, delta) {
  const links = findLinks(link.closest(LIST_SELECTOR));
  links[links.indexOf(link) + delta]?.focus();
}

// Empty and loading columns have no card links, and collapsed columns render no
// list, so skipping lists without links skips all of them.
export function focusCardInRow(link, delta) {
  const currentList = link.closest(LIST_SELECTOR);
  const lists = [...document.querySelectorAll(LIST_SELECTOR)].filter(
    (list) => findLinks(list).length > 0,
  );
  const targetList = lists[lists.indexOf(currentList) + delta];
  if (!targetList) {
    return;
  }

  const index = findLinks(currentList).indexOf(link);
  const targetLinks = findLinks(targetList);
  targetLinks[Math.min(index, targetLinks.length - 1)].focus();
}
