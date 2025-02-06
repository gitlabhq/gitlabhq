import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import IssuePopover from './components/issue_popover.vue';
import MRPopover from './components/mr_popover.vue';
import MilestonePopover from './components/milestone_popover.vue';
import CommentPopover from './components/comment_popover.vue';

export const componentsByReferenceTypeMap = {
  issue: IssuePopover,
  work_item: IssuePopover,
  merge_request: MRPopover,
  milestone: MilestonePopover,
};

let renderFn;

const handleIssuablePopoverMouseOut = ({ target }) => {
  target.removeEventListener('mouseleave', handleIssuablePopoverMouseOut);

  if (renderFn) {
    clearTimeout(renderFn);
  }
};

const popoverMountedAttr = 'data-popover-mounted';

function isCommentPopover(target) {
  const targetUrl = new URL(target.href);
  const noteId = targetUrl.hash;

  return noteId && noteId.startsWith('#note_');
}

export function handleCommentPopoverMount({ target, apolloProvider }) {
  const PopoverComponent = Vue.extend(CommentPopover);

  new PopoverComponent({
    propsData: {
      target,
    },
    apolloProvider,
  }).$mount();
}

/**
 * Adds a Popover component for issuables and work items to the body,
 * hands over as much data as the target element has in data attributes.
 * loads based on data-project-path and data-iid more data about an MR
 * from the API and sets it on the popover
 */
export const handleIssuablePopoverMount = ({
  componentsByReferenceType = componentsByReferenceTypeMap,
  apolloProvider,
  namespacePath,
  title,
  iid,
  milestone,
  innerText,
  referenceType,
  target,
  placement,
}) => {
  // Add listener to actually remove it again
  target.addEventListener('mouseleave', handleIssuablePopoverMouseOut);

  renderFn = setTimeout(() => {
    if (isCommentPopover(target)) {
      handleCommentPopoverMount({ target, apolloProvider });
    } else {
      const PopoverComponent = Vue.extend(componentsByReferenceType[referenceType]);

      new PopoverComponent({
        propsData: {
          target,
          namespacePath,
          iid,
          placement,
          milestoneId: milestone,
          cachedTitle: title || innerText,
        },
        apolloProvider,
      }).$mount();
    }

    target.setAttribute(popoverMountedAttr, true);
  }, 200); // 200ms delay so not every mouseover triggers Popover + API Call
};

export default (elements, issuablePopoverMount = handleIssuablePopoverMount) => {
  if (elements.length > 0) {
    Vue.use(VueApollo);

    const apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(),
    });
    const listenerAddedAttr = 'data-popover-listener-added';

    elements.forEach((el) => {
      const { projectPath, groupPath, iid, referenceType, milestone, placement } = el.dataset;
      let { namespacePath } = el.dataset;
      const title = el.dataset.mrTitle || el.title;
      const { innerText } = el;
      namespacePath = namespacePath || groupPath || projectPath;
      const isIssuable = Boolean(namespacePath && title && iid);
      const isMilestone = Boolean(milestone);

      if (!el.getAttribute(listenerAddedAttr) && referenceType && (isIssuable || isMilestone)) {
        el.addEventListener('mouseenter', ({ target }) => {
          if (!el.getAttribute(popoverMountedAttr)) {
            issuablePopoverMount({
              apolloProvider,
              namespacePath,
              title,
              iid,
              milestone,
              innerText,
              referenceType,
              target,
              placement,
            });
          }
        });
        el.setAttribute(listenerAddedAttr, true);
      }
    });
  }
};
