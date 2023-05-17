import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import IssuePopover from './components/issue_popover.vue';
import MRPopover from './components/mr_popover.vue';

const componentsByReferenceType = {
  issue: IssuePopover,
  work_item: IssuePopover,
  merge_request: MRPopover,
};

let renderFn;

const handleIssuablePopoverMouseOut = ({ target }) => {
  target.removeEventListener('mouseleave', handleIssuablePopoverMouseOut);

  if (renderFn) {
    clearTimeout(renderFn);
  }
};

const popoverMountedAttr = 'data-popover-mounted';

/**
 * Adds a MergeRequestPopover component to the body, hands over as much data as the target element has in data attributes.
 * loads based on data-project-path and data-iid more data about an MR from the API and sets it on the popover
 */
const handleIssuablePopoverMount = ({
  apolloProvider,
  projectPath,
  title,
  iid,
  referenceType,
  target,
}) => {
  // Add listener to actually remove it again
  target.addEventListener('mouseleave', handleIssuablePopoverMouseOut);

  renderFn = setTimeout(() => {
    const PopoverComponent = Vue.extend(componentsByReferenceType[referenceType]);
    new PopoverComponent({
      propsData: {
        target,
        projectPath,
        iid,
        cachedTitle: title,
      },
      apolloProvider,
    }).$mount();

    target.setAttribute(popoverMountedAttr, true);
  }, 200); // 200ms delay so not every mouseover triggers Popover + API Call
};

export default (elements) => {
  if (elements.length > 0) {
    Vue.use(VueApollo);

    const apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(),
    });
    const listenerAddedAttr = 'data-popover-listener-added';

    elements.forEach((el) => {
      const { projectPath, iid, referenceType } = el.dataset;
      const title = el.dataset.mrTitle || el.title;

      if (!el.getAttribute(listenerAddedAttr) && projectPath && title && iid && referenceType) {
        el.addEventListener('mouseenter', ({ target }) => {
          if (!el.getAttribute(popoverMountedAttr)) {
            handleIssuablePopoverMount({
              apolloProvider,
              projectPath,
              title,
              iid,
              referenceType,
              target,
            });
          }
        });
        el.setAttribute(listenerAddedAttr, true);
      }
    });
  }
};
