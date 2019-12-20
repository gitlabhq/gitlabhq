import '~/commons/polyfills/element';

describe('Element polyfills', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  beforeEach(() => {
    testContext.element = document.createElement('ul');
  });

  describe('matches', () => {
    it('returns true if element matches the selector', () => {
      expect(testContext.element.matches('ul')).toBeTruthy();
    });

    it("returns false if element doesn't match the selector", () => {
      expect(testContext.element.matches('.not-an-element')).toBeFalsy();
    });
  });

  describe('closest', () => {
    beforeEach(() => {
      testContext.childElement = document.createElement('li');
      testContext.element.appendChild(testContext.childElement);
    });

    it('returns the closest parent that matches the selector', () => {
      expect(testContext.childElement.closest('ul').toString()).toBe(
        testContext.element.toString(),
      );
    });

    it('returns itself if it matches the selector', () => {
      expect(testContext.childElement.closest('li').toString()).toBe(
        testContext.childElement.toString(),
      );
    });

    it('returns undefined if nothing matches the selector', () => {
      expect(testContext.childElement.closest('.no-an-element')).toBeFalsy();
    });
  });
});
