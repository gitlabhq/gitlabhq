import $ from 'jquery';
import initCopyAsGFM, { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import { setHTMLFixture } from 'helpers/fixtures';

describe('CopyAsGFM', () => {
  describe('initCopyAsGFM', () => {
    beforeEach(() => {
      jest.spyOn(CopyAsGFM, 'copyAsGFM').mockImplementation(() => {});
      jest.spyOn(CopyAsGFM, 'pasteGFM').mockImplementation(() => {});
      setHTMLFixture(`
        <div class="md"></div>
        <div class="wiki"></div>
        <pre class="code highlight"></pre>
        <div class="diff-content"><div class="line_content"></div></div>
        <div class="js-gfm-input"></div>
      `);

      initCopyAsGFM();
    });

    afterEach(() => {
      $(document).off('copy');
      $(document).off('paste');
    });

    it.each`
      selector                         | expectedTransform
      ${'.md'}                         | ${CopyAsGFM.transformGFMSelection}
      ${'.wiki'}                       | ${CopyAsGFM.transformGFMSelection}
      ${'pre.code.highlight'}          | ${CopyAsGFM.transformCodeSelection}
      ${'.diff-content .line_content'} | ${CopyAsGFM.transformCodeSelection}
    `(
      'calls copyAsGFM with $expectedTransform.name for copy event on $selector',
      ({ selector, expectedTransform }) => {
        const copyEvent = $.Event('copy');
        const $element = $(selector);
        expect($element.length).toBe(1);

        $element.trigger(copyEvent);

        expect(CopyAsGFM.copyAsGFM).toHaveBeenCalledWith(copyEvent, expectedTransform);
      },
    );

    it('calls pasteGFM for paste event on .js-gfm-input', () => {
      const pasteEvent = $.Event('paste');
      const $element = $('.js-gfm-input');
      expect($element.length).toBe(1);

      $element.trigger(pasteEvent);

      expect(CopyAsGFM.pasteGFM).toHaveBeenCalledWith(pasteEvent);
    });
  });
});
