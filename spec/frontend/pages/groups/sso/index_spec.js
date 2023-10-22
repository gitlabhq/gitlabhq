import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');

describe('SAML single sign-on page', () => {
  it('calls `renderGFM` to ensure that all gitlab-flavoured markdown is rendered on the SAML single sign-on page', async () => {
    await import('~/pages/sessions/new/index');
    expect(renderGFM).toHaveBeenCalledWith(document.body);
  });
});
