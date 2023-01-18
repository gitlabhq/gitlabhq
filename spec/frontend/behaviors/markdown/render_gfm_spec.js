import { renderGFM } from '~/behaviors/markdown/render_gfm';

describe('renderGFM', () => {
  it('handles a missing element', () => {
    expect(() => {
      renderGFM();
    }).not.toThrow();
  });
});
