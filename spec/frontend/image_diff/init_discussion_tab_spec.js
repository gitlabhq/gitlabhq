import initDiscussionTab from '~/image_diff/init_discussion_tab';
import initImageDiffHelper from '~/image_diff/helpers/init_image_diff';

describe('initDiscussionTab', () => {
  beforeEach(() => {
    setFixtures(`
      <div class="timeline-content">
        <div class="diff-file js-image-file"></div>
        <div class="diff-file js-image-file"></div>
      </div>
    `);
  });

  it('should pass canCreateNote as false to initImageDiff', done => {
    jest
      .spyOn(initImageDiffHelper, 'initImageDiff')
      .mockImplementation((diffFileEl, canCreateNote) => {
        expect(canCreateNote).toEqual(false);
        done();
      });

    initDiscussionTab();
  });

  it('should pass renderCommentBadge as true to initImageDiff', done => {
    jest
      .spyOn(initImageDiffHelper, 'initImageDiff')
      .mockImplementation((diffFileEl, canCreateNote, renderCommentBadge) => {
        expect(renderCommentBadge).toEqual(true);
        done();
      });

    initDiscussionTab();
  });

  it('should call initImageDiff for each diffFileEls', () => {
    jest.spyOn(initImageDiffHelper, 'initImageDiff').mockImplementation(() => {});
    initDiscussionTab();

    expect(initImageDiffHelper.initImageDiff.mock.calls.length).toEqual(2);
  });
});
