import initReadMore from '~/read_more';

describe('Read more click-to-expand functionality', () => {
  const fixtureName = 'projects/overview.html';

  beforeEach(() => {
    loadFixtures(fixtureName);
  });

  describe('expands target element', () => {
    it('adds "is-expanded" class to target element', () => {
      const target = document.querySelector('.read-more-container');
      const trigger = document.querySelector('.js-read-more-trigger');
      initReadMore();

      trigger.click();

      expect(target.classList.contains('is-expanded')).toEqual(true);
    });
  });
});
