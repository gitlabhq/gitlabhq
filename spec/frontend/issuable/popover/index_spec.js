import { setHTMLFixture } from 'helpers/fixtures';
import * as createDefaultClient from '~/lib/graphql';
import initIssuablePopovers, * as popover from '~/issuable/popover/index';

createDefaultClient.default = jest.fn();

describe('initIssuablePopovers', () => {
  let mr1;
  let mr2;
  let mr3;
  let issue1;
  let workItem1;
  let comment1;

  beforeEach(() => {
    setHTMLFixture(`
      <div id="one" class="gfm-merge_request" data-mr-title="title" data-iid="1" data-project-path="group/project" data-reference-type="merge_request">
        MR1
      </div>
      <div id="two" class="gfm-merge_request" title="title" data-iid="1" data-project-path="group/project" data-reference-type="merge_request">
        MR2
      </div>
      <div id="three" class="gfm-merge_request">
        MR3
      </div>
      <div id="four" class="gfm-issue" title="title" data-iid="1" data-project-path="group/project" data-reference-type="issue">
        MR3
      </div>
      <div id="five" class="gfm-work_item" title="title" data-iid="1" data-project-path="group/project" data-reference-type="work_item">
        MR3
      </div>
      <a id="note_1" href="${window.location.href}#note_2" class="gfm-issue" title="title" data-iid="1" data-project-path="group/project" data-reference-type="work_item">
        <div class="note-text">some comment text 1</div>
      </a>
    `);

    mr1 = document.querySelector('#one');
    mr2 = document.querySelector('#two');
    mr3 = document.querySelector('#three');
    issue1 = document.querySelector('#four');
    workItem1 = document.querySelector('#five');
    comment1 = document.querySelector('#note_1');
  });

  describe('init function', () => {
    beforeEach(() => {
      mr1.addEventListener = jest.fn();
      mr2.addEventListener = jest.fn();
      mr3.addEventListener = jest.fn();
      issue1.addEventListener = jest.fn();
      workItem1.addEventListener = jest.fn();
      comment1.addEventListener = jest.fn();
    });

    it('does not add the same event listener twice', () => {
      initIssuablePopovers([mr1, mr1, mr2, issue1, workItem1, comment1]);

      expect(mr1.addEventListener).toHaveBeenCalledTimes(1);
      expect(mr2.addEventListener).toHaveBeenCalledTimes(1);
      expect(issue1.addEventListener).toHaveBeenCalledTimes(1);
      expect(workItem1.addEventListener).toHaveBeenCalledTimes(1);
      expect(comment1.addEventListener).toHaveBeenCalledTimes(1);
    });

    it('does not add listener if it does not have the necessary data attributes', () => {
      initIssuablePopovers([mr1, mr2, mr3]);

      expect(mr3.addEventListener).not.toHaveBeenCalled();
    });
  });

  describe('mount function', () => {
    const expectedMountObject = {
      apolloProvider: expect.anything(),
      iid: '1',
      namespacePath: 'group/project',
      title: 'title',
    };

    beforeEach(() => {
      jest.spyOn(popover, 'handleIssuablePopoverMount').mockImplementation(jest.fn());
    });

    it('calls popover mount function with components for Issue, MR, and Work Item', () => {
      initIssuablePopovers([mr1, issue1, workItem1], popover.handleIssuablePopoverMount);

      [mr1, issue1, workItem1].forEach(async (el) => {
        await el.dispatchEvent(new Event('mouseenter', { target: el }));

        expect(popover.handleIssuablePopoverMount).toHaveBeenCalledWith(
          expect.objectContaining({
            ...expectedMountObject,
            referenceType: el.dataset.referenceType,
            target: el,
          }),
        );
      });
    });
  });

  describe('comment tooltips', () => {
    it('calls popover mount function for comments', async () => {
      jest.spyOn(popover, 'handleIssuablePopoverMount').mockImplementation(jest.fn());

      initIssuablePopovers([comment1], popover.handleIssuablePopoverMount);

      await comment1.dispatchEvent(new Event('mouseenter', { target: comment1 }));

      expect(popover.handleIssuablePopoverMount).toHaveBeenCalledWith(
        expect.objectContaining({
          apolloProvider: expect.anything(),
          iid: '1',
          namespacePath: 'group/project',
          title: 'title',
          referenceType: comment1.dataset.referenceType,
          target: comment1,
        }),
      );
    });
  });
});
