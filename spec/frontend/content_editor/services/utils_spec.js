import { rectUnion } from '~/content_editor/services/utils';

describe('rectUnion', () => {
  const verifyRect = (actual, expected) => {
    expect(actual).toBeInstanceOf(DOMRect);
    expect(actual.left).toBe(expected.left);
    expect(actual.top).toBe(expected.top);
    expect(actual.right).toBe(expected.right);
    expect(actual.bottom).toBe(expected.bottom);
    expect(actual.width).toBe(expected.width);
    expect(actual.height).toBe(expected.height);
  };

  it('returns default DOMRect when no rectangles are provided', () => {
    const result = rectUnion();
    verifyRect(result, {
      left: -1000,
      top: -1000,
      right: -1000,
      bottom: -1000,
      width: 0,
      height: 0,
    });
  });

  it('filters out null and undefined values', () => {
    const rect = new DOMRect(10, 20, 30, 40);
    const result = rectUnion(null, rect, undefined);
    verifyRect(result, {
      left: 10,
      top: 20,
      right: 40, // left + width
      bottom: 60, // top + height
      width: 30,
      height: 40,
    });
  });

  it('returns the same rectangle when only one is provided', () => {
    const rect = new DOMRect(10, 20, 30, 40);
    const result = rectUnion(rect);
    expect(result).toBe(rect); // Should be the exact same reference
  });

  it('computes union of two non-overlapping rectangles', () => {
    const rect1 = new DOMRect(10, 10, 20, 20);
    const rect2 = new DOMRect(50, 50, 20, 20);
    const result = rectUnion(rect1, rect2);
    verifyRect(result, {
      left: 10,
      top: 10,
      right: 70, // rect2.left + rect2.width
      bottom: 70, // rect2.top + rect2.height
      width: 60, // right - left
      height: 60, // bottom - top
    });
  });

  it('computes union of two overlapping rectangles', () => {
    const rect1 = new DOMRect(10, 10, 30, 30);
    const rect2 = new DOMRect(30, 30, 30, 30);
    const result = rectUnion(rect1, rect2);
    verifyRect(result, {
      left: 10,
      top: 10,
      right: 60, // rect2.left + rect2.width
      bottom: 60, // rect2.top + rect2.height
      width: 50, // right - left
      height: 50, // bottom - top
    });
  });

  it('handles rectangles where one contains the other', () => {
    const container = new DOMRect(0, 0, 100, 100);
    const contained = new DOMRect(25, 25, 50, 50);
    const result = rectUnion(container, contained);
    verifyRect(result, {
      left: 0,
      top: 0,
      right: 100,
      bottom: 100,
      width: 100,
      height: 100,
    });
  });

  it('handles rectangles with negative coordinates', () => {
    const rect1 = new DOMRect(-30, -20, 40, 30);
    const rect2 = new DOMRect(10, -50, 20, 40);
    const result = rectUnion(rect1, rect2);
    verifyRect(result, {
      left: -30,
      top: -50,
      right: 30, // rect2.left + rect2.width
      bottom: 10, // rect1.top + rect1.height
      width: 60, // right - left
      height: 60, // bottom - top
    });
  });

  it('computes union of many rectangles correctly', () => {
    const rects = [
      new DOMRect(0, 0, 10, 10),
      new DOMRect(20, 15, 5, 10),
      new DOMRect(5, 30, 15, 5),
      new DOMRect(-10, 5, 8, 8),
    ];
    const result = rectUnion(...rects);
    verifyRect(result, {
      left: -10,
      top: 0,
      right: 25, // rects[1].left + rects[1].width
      bottom: 35, // rects[2].top + rects[2].height
      width: 35, // right - left
      height: 35, // bottom - top
    });
  });

  it('handles rectangles with zero width or height', () => {
    const rect1 = new DOMRect(10, 10, 0, 20);
    const rect2 = new DOMRect(30, 30, 20, 0);
    const result = rectUnion(rect1, rect2);
    verifyRect(result, {
      left: 10,
      top: 10,
      right: 50, // rect2.left + rect2.width
      bottom: 30, // rect1.top + rect1.height
      width: 40, // right - left
      height: 20, // bottom - top
    });
  });
});
