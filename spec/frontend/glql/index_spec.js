import renderGlqlNodes from '~/glql';

jest.mock('~/lib/graphql');
jest.mock('~/glql/core/parser/query');

describe('renderGlqlNodes', () => {
  it('loops over all glql code blocks and renders them', async () => {
    const container = document.createElement('div');
    container.innerHTML = `
      <pre data-canonical-lang="glql"><code>assignee = currentUser()</code></pre>
      <pre data-canonical-lang="glql"><code>label = "bug"</code></pre>
    `;

    await renderGlqlNodes(container.querySelectorAll('[data-canonical-lang="glql"]'));

    expect(container.querySelectorAll('[data-testid="glql-facade"]')).toHaveLength(2);
  });
});
