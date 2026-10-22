import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { BOARD_CARD_LINK_CLASS, BOARD_CARD_LIST_CLASS } from '~/work_items/board/constants';
import {
  FOCUS_NEXT,
  FOCUS_PREVIOUS,
  focusCardInColumn,
  focusCardInRow,
} from '~/work_items/board/keyboard_navigation';

const cards = (column, count) =>
  Array.from(
    { length: count },
    (_, index) =>
      `<li><a class="${BOARD_CARD_LINK_CLASS}" href="#" data-testid="card-${column}-${index}">${column} ${index}</a></li>`,
  ).join('');

// A has 3 cards, B is empty, C has 5, a collapsed column renders no list, D has 1.
const fixture = `
  <ul class="${BOARD_CARD_LIST_CLASS}">${cards('A', 3)}</ul>
  <ul class="${BOARD_CARD_LIST_CLASS}"><li data-testid="empty-state">No items</li></ul>
  <ul class="${BOARD_CARD_LIST_CLASS}">${cards('C', 5)}</ul>
  <div data-testid="collapsed-column"></div>
  <ul class="${BOARD_CARD_LIST_CLASS}">${cards('D', 1)}</ul>
`;

describe('board keyboard navigation', () => {
  const findCard = (column, index) =>
    document.querySelector(`[data-testid="card-${column}-${index}"]`);

  const focusCard = (column, index) => {
    const card = findCard(column, index);
    card.focus();
    return card;
  };

  beforeEach(() => {
    setHTMLFixture(fixture);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('focusCardInColumn', () => {
    it('focuses the next card when moving down', () => {
      focusCardInColumn(focusCard('A', 0), FOCUS_NEXT);

      expect(document.activeElement).toBe(findCard('A', 1));
    });

    it('focuses the previous card when moving up', () => {
      focusCardInColumn(focusCard('A', 2), FOCUS_PREVIOUS);

      expect(document.activeElement).toBe(findCard('A', 1));
    });

    it('keeps focus on the first card when moving up from it', () => {
      focusCardInColumn(focusCard('A', 0), FOCUS_PREVIOUS);

      expect(document.activeElement).toBe(findCard('A', 0));
    });

    it('keeps focus on the last card when moving down from it', () => {
      focusCardInColumn(focusCard('C', 4), FOCUS_NEXT);

      expect(document.activeElement).toBe(findCard('C', 4));
    });

    it('does not move into another column', () => {
      focusCardInColumn(focusCard('A', 2), FOCUS_NEXT);

      expect(document.activeElement).toBe(findCard('A', 2));
    });
  });

  describe('focusCardInRow', () => {
    it('focuses the card at the same index in the next column with cards', () => {
      focusCardInRow(focusCard('A', 1), FOCUS_NEXT);

      expect(document.activeElement).toBe(findCard('C', 1));
    });

    it('skips a column with no cards', () => {
      focusCardInRow(focusCard('C', 0), FOCUS_PREVIOUS);

      expect(document.activeElement).toBe(findCard('A', 0));
    });

    it('skips a collapsed column that renders no list', () => {
      focusCardInRow(focusCard('C', 0), FOCUS_NEXT);

      expect(document.activeElement).toBe(findCard('D', 0));
    });

    it.each`
      direction  | delta             | expected
      ${'right'} | ${FOCUS_NEXT}     | ${['D', 0]}
      ${'left'}  | ${FOCUS_PREVIOUS} | ${['A', 2]}
    `(
      'focuses the last card when the column to the $direction is shorter',
      ({ delta, expected }) => {
        focusCardInRow(focusCard('C', 4), delta);

        expect(document.activeElement).toBe(findCard(...expected));
      },
    );

    it.each`
      direction  | column | delta
      ${'left'}  | ${'A'} | ${FOCUS_PREVIOUS}
      ${'right'} | ${'D'} | ${FOCUS_NEXT}
    `('keeps focus when there is no column to the $direction', ({ column, delta }) => {
      focusCardInRow(focusCard(column, 0), delta);

      expect(document.activeElement).toBe(findCard(column, 0));
    });
  });
});
