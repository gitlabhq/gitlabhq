import { renderDuoChatMarkdownPreview } from '@gitlab/duo-ui/dist/components/chat/markdown_renderer';
import renderGlqlNodes from '~/glql';
import { stubCrypto } from 'helpers/crypto';

jest.mock('~/lib/graphql');
jest.mock('~/glql/core/parser');

// Guards the cross-package DOM contract between @gitlab/duo-ui's chat markdown
// renderer and GitLab's GLQL mounting. Driving a real ```glql fence through the
// real duo-ui renderer means a future wrapper rename fails here when the
// dependency is bumped, instead of silently breaking Duo Chat:
// https://gitlab.com/gitlab-org/gitlab/-/work_items/601932
describe('GLQL rendering inside the real Duo Chat markdown wrapper', () => {
  stubCrypto();

  beforeEach(async () => {
    document.body.innerHTML = await renderDuoChatMarkdownPreview(
      '```glql\nassignee = currentUser()\n```',
    );
  });

  it('emits a glql code block that render_gfm can detect', () => {
    // Mirrors the selector in app/assets/javascripts/behaviors/markdown/render_gfm.js
    expect(document.querySelector('[data-canonical-lang="glql"], .language-glql')).not.toBeNull();
  });

  it('replaces the entire duo-ui code-block wrapper, not just the inner pre', async () => {
    const glqlEl = document.querySelector('[data-canonical-lang="glql"], .language-glql');
    // Capture the duo-ui wrapper by reference, not by class name: the assertion
    // must hold even if duo-ui renames the wrapper class (which is what regressed).
    const wrapper = glqlEl.closest('pre').parentElement;
    expect(wrapper).not.toBe(document.body);

    await renderGlqlNodes([glqlEl]);

    expect(document.querySelector('[data-testid="glql-facade"]')).not.toBeNull();
    // If only the <pre> were replaced, this wrapper would stay in the DOM and the
    // facade would remain a shrink-wrapped flex child instead of filling the width.
    expect(document.body.contains(wrapper)).toBe(false);
  });
});
