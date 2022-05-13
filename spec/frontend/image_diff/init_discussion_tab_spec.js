import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initImageDiffHelper from '~/image_diff/helpers/init_image_diff';
import initDiscussionTab from '~/image_diff/init_discussion_tab';

describe('initDiscussionTab', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <div class="timeline-content">
        <div class="diff-file js-image-file"></div>
        <div class="diff-file js-image-file"></div>
      </div>
    `);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('should pass canCreateNote as false to initImageDiff', () => {
    jest
      .spyOn(initImageDiffHelper, 'initImageDiff')
      .mockImplementation((diffFileEl, canCreateNote) => {
        expect(canCreateNote).toEqual(false);
      });

    initDiscussionTab();
  });

  it('should pass renderCommentBadge as true to initImageDiff', () => {
    jest
      .spyOn(initImageDiffHelper, 'initImageDiff')
      .mockImplementation((diffFileEl, canCreateNote, renderCommentBadge) => {
        expect(renderCommentBadge).toEqual(true);
      });

    initDiscussionTab();
  });

  it('should call initImageDiff for each diffFileEls', () => {
    jest.spyOn(initImageDiffHelper, 'initImageDiff').mockImplementation(() => {});
    initDiscussionTab();

    expect(initImageDiffHelper.initImageDiff.mock.calls.length).toEqual(2);
  });
});
