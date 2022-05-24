import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import MRPopover from './components/mr_popover.vue';

let renderedPopover;
let renderFn;

const handleIssuablePopoverMouseOut = ({ target }) => {
  target.removeEventListener('mouseleave', handleIssuablePopoverMouseOut);

  if (renderFn) {
    clearTimeout(renderFn);
  }
  if (renderedPopover) {
    renderedPopover.$destroy();
    renderedPopover = null;
  }
};

/**
 * Adds a MergeRequestPopover component to the body, hands over as much data as the target element has in data attributes.
 * loads based on data-project-path and data-iid more data about an MR from the API and sets it on the popover
 */
const handleIssuablePopoverMount = ({ apolloProvider, projectPath, title, iid }) => ({
  target,
}) => {
  // Add listener to actually remove it again
  target.addEventListener('mouseleave', handleIssuablePopoverMouseOut);

  renderFn = setTimeout(() => {
    const MRPopoverComponent = Vue.extend(MRPopover);
    renderedPopover = new MRPopoverComponent({
      propsData: {
        target,
        projectPath,
        mergeRequestIID: iid,
        mergeRequestTitle: title,
      },
      apolloProvider,
    });

    renderedPopover.$mount();
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
      const { projectPath, iid } = el.dataset;
      const title = el.dataset.mrTitle || el.title;

      if (!el.getAttribute(listenerAddedAttr) && projectPath && title && iid) {
        el.addEventListener(
          'mouseenter',
          handleIssuablePopoverMount({ apolloProvider, projectPath, title, iid }),
        );
        el.setAttribute(listenerAddedAttr, true);
      }
    });
  }
};
