import { renderGFM } from '~/behaviors/markdown/render_gfm';

jest.mock('~/behaviors/markdown/render_gfm');

describe('CI/CD Settings', () => {
  it('calls `renderGFM` to ensure that all gitlab-flavoured markdown is rendered on the CI/CD Settings page', async () => {
    jest.spyOn(document, 'getElementById').getMockImplementation();
    await import('~/pages/projects/settings/ci_cd/show');
    expect(document.getElementById).toHaveBeenCalledWith('js-shared-runners-markdown');
    expect(renderGFM).toHaveBeenCalledTimes(1);
  });
});
