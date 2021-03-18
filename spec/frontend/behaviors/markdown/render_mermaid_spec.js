import { initMermaid } from '~/behaviors/markdown/render_mermaid';
import * as ColorUtils from '~/lib/utils/color_utils';

describe('Render mermaid diagrams for Gitlab Flavoured Markdown', () => {
  it.each`
    darkMode | expectedTheme
    ${false} | ${'neutral'}
    ${true}  | ${'dark'}
  `('is $darkMode $expectedTheme', async ({ darkMode, expectedTheme }) => {
    jest.spyOn(ColorUtils, 'darkModeEnabled').mockImplementation(() => darkMode);

    const mermaid = {
      initialize: jest.fn(),
    };

    await initMermaid(mermaid);

    expect(mermaid.initialize).toHaveBeenCalledTimes(1);
    expect(mermaid.initialize).toHaveBeenCalledWith(
      expect.objectContaining({
        theme: expectedTheme,
      }),
    );
  });
});
