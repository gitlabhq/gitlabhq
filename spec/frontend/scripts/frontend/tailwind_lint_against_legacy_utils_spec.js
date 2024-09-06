import { lintAgainstLegacyUtils } from '../../../../scripts/frontend/tailwind_lint_against_legacy_utils';

describe('lintAgainstLegacyUtils', () => {
  beforeEach(() => {
    jest.spyOn(console, 'log').mockImplementation(jest.fn());
    jest.spyOn(console, 'warn').mockImplementation(jest.fn());
  });

  it('does not throw if no legacy utils are used', async () => {
    await expect(
      lintAgainstLegacyUtils({ content: [{ raw: '<div class="gl-block">', extension: 'html' }] }),
    ).resolves.not.toThrow();
  });

  describe('legacy utils are used', () => {
    it('does throw on basic legacy utils', async () => {
      await expect(
        lintAgainstLegacyUtils({
          content: [{ raw: '<div class="gl-display-block">', extension: 'html' }],
        }),
      ).rejects.toThrow(/You are introducing legacy utilities[\s\S]+\.gl-display-block/gm);
    });

    it('does throw with modified legacy utils', async () => {
      await expect(
        lintAgainstLegacyUtils({
          content: [{ raw: '<div class="md:gl-display-block">', extension: 'html' }],
        }),
      ).rejects.toThrow(/You are introducing legacy utilities[\s\S]+\.md\\:gl-display-block/gm);
    });

    it('does throw with important legacy utils', async () => {
      await expect(
        lintAgainstLegacyUtils({
          content: [{ raw: '<div class="!gl-display-block">', extension: 'html' }],
        }),
      ).rejects.toThrow(/You are introducing legacy utilities[\s\S]+\.\\!gl-display-block/gm);
    });
  });
});
