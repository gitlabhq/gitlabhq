import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { defaultClient } from '~/graphql_shared/issuable_client';
import { handleIssuablePopoverMount } from 'ee_else_ce/issuable/popover';

/**
 * This method is based on default function of app/assets/javascripts/issuable/popover/index.js
 * where we bind popover mount function to all elements qualifying for popovers.
 *
 * In case of Work Items, where contents are often loaded async (i.e. in drawer and modals), relying
 * on default popover mount function is not possible and we need to attach a global event listener on
 * document to ensure that popover is mounted on qualifying element when mouse is hovered over it. However
 * the logic is still similar to how GFM popover functions.
 *
 * For any Work Item attribute to have popover, it needs to contain following attributes;
 *
 * CSS Class: `has-popover`
 * Following Data attributes:
 *  - data-reference-type: This can be `issue`, `work_item`, `merge_request`, or `milestone`
 *  - data-placement: Placement of popover, default is `top`.
 *  - data-iid: Internal ID of the work item or issuable (in case reference type is Issue, WI, or MR)
 *              not required for `milestone`.
 *  - data-group-path:  Path of work item or issuable if it is group-level, not required for `milestone`
 *  - data-project-path:  Path of work item or issuable if it is project-level, not required for `milestone`
 *  - data-milestone: Milestone ID.
 */
export default function initWorkItemAttributePopovers() {
  Vue.use(VueApollo);
  const apolloProvider = new VueApollo({
    defaultClient,
  });
  const listenerAddedAttr = 'data-popover-listener-added';
  const popoverMountedAttr = 'data-popover-mounted';

  document.addEventListener('mouseover', ({ target }) => {
    // Return if target doesn't qualify for popover
    if (
      !target.classList.contains('has-popover') ||
      !target.dataset.referenceType ||
      target.hasAttribute(listenerAddedAttr)
    ) {
      return;
    }

    // Extract required metadata
    const { referenceType, placement, iid, title, groupPath, projectPath, milestone } =
      target.dataset;
    let { namespacePath } = target.dataset;
    namespacePath = namespacePath || groupPath || projectPath;
    const { innerText } = target;

    // Attach mount listener to target
    target.addEventListener('mouseenter', (e) => {
      if (!target.getAttribute(popoverMountedAttr)) {
        handleIssuablePopoverMount({
          target: e.target,
          apolloProvider,
          referenceType,
          placement,
          namespacePath,
          iid,
          title,
          milestone,
          innerText: innerText.trim(),
        });
      }
    });
    // Ensure that listener is only added once
    target.setAttribute(listenerAddedAttr, true);
  });
}
