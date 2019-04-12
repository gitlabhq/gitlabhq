import Vue from 'vue';
import VueApollo from 'vue-apollo';
import MRPopover from './components/mr_popover.vue';
import createDefaultClient from '~/lib/graphql';

let renderedPopover;
let renderFn;

const handleUserPopoverMouseOut = ({ target }) => {
  target.removeEventListener('mouseleave', handleUserPopoverMouseOut);

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
const handleMRPopoverMount = apolloProvider => ({ target }) => {
  // Add listener to actually remove it again
  target.addEventListener('mouseleave', handleUserPopoverMouseOut);

  const { projectPath, mrTitle, iid } = target.dataset;
  const mergeRequest = {};

  renderFn = setTimeout(() => {
    const MRPopoverComponent = Vue.extend(MRPopover);
    renderedPopover = new MRPopoverComponent({
      propsData: {
        target,
        projectPath,
        mergeRequestIID: iid,
        mergeRequest,
        mergeRequestTitle: mrTitle,
      },
      apolloProvider,
    });

    renderedPopover.$mount();
  }, 200); // 200ms delay so not every mouseover triggers Popover + API Call
};

export default elements => {
  const mrLinks = elements || [...document.querySelectorAll('.gfm-merge_request')];
  if (mrLinks.length > 0) {
    Vue.use(VueApollo);

    const apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(),
    });
    const listenerAddedAttr = 'data-mr-listener-added';

    mrLinks.forEach(el => {
      if (!el.getAttribute(listenerAddedAttr)) {
        el.addEventListener('mouseenter', handleMRPopoverMount(apolloProvider));
        el.setAttribute(listenerAddedAttr, true);
      }
    });
  }
};
