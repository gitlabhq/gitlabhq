describe('Sidebar', () => {
  preloadFixtures('issues/open-issue.html.raw');

  beforeEach(() => loadFixtures('issues/open-issue.html.raw'));

  it('does not have a max select', () => {
    const dropdown = document.querySelector('.js-author-search');

    expect(dropdown.dataset.maxSelect).toBeUndefined();
  });
});
