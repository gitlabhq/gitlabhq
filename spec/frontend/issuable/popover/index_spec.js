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
  let milestone1;
  let iteration1;
  let commit1;
  let commit2;

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
      <div id="six" class="gfm-milestone" data-milestone="1" data-namespace-path="group/project" data-reference-type="milestone">
        Milestone 1
      </div>
      <div id="seven" class="gfm-iteration" data-iteration="1" data-namespace-path="group/project" data-reference-type="iteration">
        Iteration 1
      </div>
      <a id="eight" class="gfm gfm-commit has-tooltip" title="Fix bug in feature" data-commit="abc123de" data-project-path="gitlab-org/gitlab-test" data-reference-type="commit">
        abc123de
      </a>
      <a id="nine" class="gfm gfm-commit" data-commit="abc123de" data-reference-type="commit">
        abc123de
      </a>
    `);

    mr1 = document.querySelector('#one');
    mr2 = document.querySelector('#two');
    mr3 = document.querySelector('#three');
    issue1 = document.querySelector('#four');
    workItem1 = document.querySelector('#five');
    comment1 = document.querySelector('#note_1');
    milestone1 = document.querySelector('#six');
    iteration1 = document.querySelector('#seven');
    commit1 = document.querySelector('#eight');
    commit2 = document.querySelector('#nine');
  });

  describe('init function', () => {
    beforeEach(() => {
      mr1.addEventListener = jest.fn();
      mr2.addEventListener = jest.fn();
      mr3.addEventListener = jest.fn();
      issue1.addEventListener = jest.fn();
      workItem1.addEventListener = jest.fn();
      comment1.addEventListener = jest.fn();
      milestone1.addEventListener = jest.fn();
      iteration1.addEventListener = jest.fn();
    });

    it('does not add the same event listener twice', () => {
      initIssuablePopovers([mr1, mr1, mr2, issue1, workItem1, comment1, milestone1, iteration1]);

      expect(mr1.addEventListener).toHaveBeenCalledTimes(1);
      expect(mr2.addEventListener).toHaveBeenCalledTimes(1);
      expect(issue1.addEventListener).toHaveBeenCalledTimes(1);
      expect(workItem1.addEventListener).toHaveBeenCalledTimes(1);
      expect(comment1.addEventListener).toHaveBeenCalledTimes(1);
      expect(milestone1.addEventListener).toHaveBeenCalledTimes(1);
      expect(iteration1.addEventListener).toHaveBeenCalledTimes(1);
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

  describe('non-anchor elements with popover', () => {
    it('does not crash when target has no href', () => {
      jest.spyOn(popover, 'handleIssuablePopoverMount').mockImplementation(jest.fn());

      initIssuablePopovers([milestone1], popover.handleIssuablePopoverMount);

      expect(() => {
        milestone1.dispatchEvent(new Event('mouseenter', { target: milestone1 }));
      }).not.toThrow();
    });
  });

  describe('milestone popovers', () => {
    beforeEach(() => {
      jest.spyOn(popover, 'handleIssuablePopoverMount').mockImplementation(jest.fn());
    });

    it('calls popover mount function with milestone data attribute', async () => {
      initIssuablePopovers([milestone1], popover.handleIssuablePopoverMount);

      await milestone1.dispatchEvent(new Event('mouseenter', { target: milestone1 }));

      expect(popover.handleIssuablePopoverMount).toHaveBeenCalledWith(
        expect.objectContaining({
          apolloProvider: expect.anything(),
          namespacePath: 'group/project',
          milestone: '1',
          iteration: undefined,
          referenceType: 'milestone',
          target: milestone1,
        }),
      );
    });
  });

  describe('iteration popovers', () => {
    beforeEach(() => {
      jest.spyOn(popover, 'handleIssuablePopoverMount').mockImplementation(jest.fn());
    });

    it('calls popover mount function with iteration data attribute', async () => {
      initIssuablePopovers([iteration1], popover.handleIssuablePopoverMount);

      await iteration1.dispatchEvent(new Event('mouseenter', { target: iteration1 }));

      expect(popover.handleIssuablePopoverMount).toHaveBeenCalledWith(
        expect.objectContaining({
          apolloProvider: expect.anything(),
          namespacePath: 'group/project',
          milestone: undefined,
          iteration: '1',
          referenceType: 'iteration',
          target: iteration1,
        }),
      );
    });
  });

  describe('handleIssuablePopoverMount', () => {
    const StubPopover = { render: (h) => h('div') };
    let onMount;
    let cancel;

    beforeEach(() => {
      onMount = jest.fn();
      cancel = popover.handleIssuablePopoverMount({
        componentsByReferenceType: { merge_request: StubPopover },
        referenceType: 'merge_request',
        target: mr1,
        namespacePath: 'group/project',
        iid: '1',
        onMount,
      });
    });

    it('mounts after the delay and reports it', () => {
      jest.runAllTimers();

      expect(mr1.dataset.popoverMounted).toBe('true');
      expect(onMount).toHaveBeenCalledTimes(1);
    });

    describe('when the returned cancel runs before the delay', () => {
      beforeEach(() => {
        cancel();
        jest.runAllTimers();
      });

      it('does not mount', () => {
        expect(mr1.dataset.popoverMounted).toBeUndefined();
        expect(onMount).not.toHaveBeenCalled();
      });
    });

    describe('when a second target arms and the pointer then leaves the first', () => {
      beforeEach(() => {
        popover.handleIssuablePopoverMount({
          componentsByReferenceType: { merge_request: StubPopover },
          referenceType: 'merge_request',
          target: mr2,
          namespacePath: 'group/project',
          iid: '1',
        });
        mr1.dispatchEvent(new MouseEvent('mouseleave'));
        jest.runAllTimers();
      });

      it('cancels only the target that was left', () => {
        expect(mr1.dataset.popoverMounted).toBeUndefined();
        expect(mr2.dataset.popoverMounted).toBe('true');
      });
    });

    describe('when cancelOnMouseLeave is false and the pointer leaves', () => {
      beforeEach(() => {
        popover.handleIssuablePopoverMount({
          componentsByReferenceType: { merge_request: StubPopover },
          referenceType: 'merge_request',
          target: mr2,
          namespacePath: 'group/project',
          iid: '1',
          cancelOnMouseLeave: false,
        });
        mr2.dispatchEvent(new MouseEvent('mouseleave'));
        jest.runAllTimers();
      });

      it('still mounts', () => {
        expect(mr2.dataset.popoverMounted).toBe('true');
      });
    });

    it('passes the mounted popover to onMount', () => {
      jest.runAllTimers();

      expect(onMount).toHaveBeenCalledWith(
        expect.objectContaining({ $destroy: expect.any(Function) }),
      );
    });

    describe('for a commit', () => {
      let receivedProps;

      beforeEach(() => {
        const CommitStub = {
          props: ['target', 'commitSha', 'projectPath'],
          created() {
            receivedProps = { commitSha: this.commitSha, projectPath: this.projectPath };
          },
          render: (h) => h('div'),
        };

        popover.handleIssuablePopoverMount({
          componentsByReferenceType: { commit: CommitStub },
          referenceType: 'commit',
          target: commit1,
          commitSha: 'abc123de',
          projectPath: 'gitlab-org/gitlab-test',
        });
        jest.runAllTimers();
      });

      it('passes the commit sha and project path to the popover', () => {
        expect(receivedProps).toEqual({
          commitSha: 'abc123de',
          projectPath: 'gitlab-org/gitlab-test',
        });
      });
    });
  });

  describe('commit popovers', () => {
    beforeEach(() => {
      jest.spyOn(popover, 'handleIssuablePopoverMount').mockImplementation(jest.fn());
    });

    it('adds a mouseenter listener for commit elements with data-commit and data-project-path', () => {
      commit1.addEventListener = jest.fn();
      initIssuablePopovers([commit1], popover.handleIssuablePopoverMount);

      expect(commit1.addEventListener).toHaveBeenCalled();
    });

    it('does not add a listener for commit elements missing data-project-path', () => {
      commit2.addEventListener = jest.fn();
      initIssuablePopovers([commit2], popover.handleIssuablePopoverMount);

      expect(commit2.addEventListener).not.toHaveBeenCalled();
    });

    it('removes title attribute and has-tooltip class on mouseenter', async () => {
      initIssuablePopovers([commit1], popover.handleIssuablePopoverMount);

      await commit1.dispatchEvent(new Event('mouseenter', { target: commit1 }));

      expect(commit1.getAttribute('title')).toBeNull();
      expect(commit1.classList.contains('has-tooltip')).toBe(false);
    });

    it('passes the commit sha and project path to the mount function', async () => {
      initIssuablePopovers([commit1], popover.handleIssuablePopoverMount);

      await commit1.dispatchEvent(new Event('mouseenter', { target: commit1 }));

      expect(popover.handleIssuablePopoverMount).toHaveBeenCalledWith(
        expect.objectContaining({
          referenceType: 'commit',
          target: commit1,
          commitSha: 'abc123de',
          projectPath: 'gitlab-org/gitlab-test',
        }),
      );

      expect(popover.handleIssuablePopoverMount).not.toHaveBeenCalledWith(
        expect.objectContaining({
          namespacePath: expect.anything(),
          iid: expect.anything(),
        }),
      );
    });
  });
});
