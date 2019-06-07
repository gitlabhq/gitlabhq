import Prism from '~/notebook/lib/highlight';

describe('Highlight library', () => {
  it('imports python language', () => {
    expect(Prism.languages.python).toBeDefined();
  });

  it('uses custom CSS classes', () => {
    const el = document.createElement('div');
    el.innerHTML = Prism.highlight('console.log("a");', Prism.languages.javascript);

    expect(el.querySelector('.s')).not.toBeNull();
    expect(el.querySelector('.nf')).not.toBeNull();
  });
});
