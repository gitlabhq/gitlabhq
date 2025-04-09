import renderGlqlNodes from '~/glql';
import { stubCrypto } from 'helpers/crypto';

jest.mock('~/lib/graphql');
jest.mock('~/glql/core/parser/query');

describe('renderGlqlNodes', () => {
  stubCrypto();

  it('loops over all glql code blocks and renders them', async () => {
    const container = document.createElement('div');
    container.innerHTML = `
      <div class="gl-relative markdown-code-block js-markdown-code"><pre data-canonical-lang="glql"><code>assignee = currentUser()</code></pre></div>
      <div class="gl-relative markdown-code-block js-markdown-code"><pre data-canonical-lang="glql"><code>label = "bug"</code></pre></div>
    `;

    await renderGlqlNodes(
      [...container.querySelectorAll('[data-canonical-lang="glql"]')].map((el) => el.parentNode),
    );

    expect(container.querySelectorAll('[data-testid="glql-facade"]')).toHaveLength(2);
  });
});
