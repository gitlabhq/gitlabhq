import renderGlqlNodes from '~/glql';
import { stubCrypto } from 'helpers/crypto';

jest.mock('~/lib/graphql');
jest.mock('~/glql/core/parser');

describe('renderGlqlNodes', () => {
  stubCrypto();

  let container;

  beforeEach(async () => {
    container = document.createElement('div');
    container.innerHTML = `
      <div class="gl-relative markdown-code-block js-markdown-code"><pre data-canonical-lang="glql"><code>assignee = currentUser()</code><copy-code>button</copy-code></pre></div>
      <div class="gl-relative markdown-code-block js-markdown-code"><pre data-canonical-lang="glql"><code>label = "bug"</code><copy-code>button</copy-code></pre></div>
      <div><pre><code class="language-glql">labels = any</code></pre></div>
    `;

    await renderGlqlNodes([
      ...container.querySelectorAll('[data-canonical-lang="glql"], .language-glql'),
    ]);
  });

  it('loops over all glql code blocks and renders them', () => {
    expect(container.querySelectorAll('[data-testid="glql-facade"]')).toHaveLength(3);
  });

  it('does not render the copy-code button', () => {
    expect(container.querySelector('copy-code')).toBeNull();
  });

  it('does not render glql nodes without a parent element', async () => {
    const orphanedPre = document.createElement('pre');
    orphanedPre.dataset.canonicalLang = 'glql';
    orphanedPre.innerHTML = '<code>assignee = currentUser()</code>';

    await renderGlqlNodes([orphanedPre]);

    expect(orphanedPre.querySelector('[data-testid="glql-facade"]')).toBeNull();
  });
});
