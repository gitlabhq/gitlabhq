import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');

describe('Preview sign in', () => {
  it('calls `renderGFM` to ensure that all gitlab-flavoured markdown is rendered on the preview sign in page', async () => {
    await import('~/pages/sessions/new/index');
    expect(renderGFM).toHaveBeenCalledWith(document.body);
  });
});
