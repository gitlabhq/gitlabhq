import { hasScrolled, markAsScrolled } from '~/rapid_diffs/utils/scroll_to_linked_fragment';

describe('scroll_to_linked_fragment', () => {
  it('returns false before scrolling', () => {
    expect(hasScrolled()).toBe(false);
  });

  it('returns true after markAsScrolled', () => {
    markAsScrolled();
    expect(hasScrolled()).toBe(true);
  });
});
