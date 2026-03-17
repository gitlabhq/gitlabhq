import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { defaultClient } from '~/graphql_shared/issuable_client';
import { handleIssuablePopoverMount } from '~/issuable/popover';

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
 *  - data-reference-type: This can be `issue`, `work_item`, `merge_request`, `milestone`, or `iteration`
 *  - data-placement: Placement of popover, default is `top`.
 *  - data-iid: Internal ID of the work item or issuable (in case reference type is Issue, WI, or MR)
 *              not required for `milestone` or `iteration`.
 *  - data-group-path:  Path of work item or issuable if it is group-level, not required for `milestone` or `iteration`
 *  - data-project-path:  Path of work item or issuable if it is project-level, not required for `milestone` or `iteration`
 *  - data-milestone: Milestone ID.
 *  - data-iteration: Iteration ID.
 */
export default function initWorkItemAttributePopovers() {
  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient,
  });

  document.addEventListener('mouseover', ({ target }) => {
    const popoverTarget = target.closest('.has-popover');

    // No popover target found
    if (!popoverTarget) return;

    const {
      referenceType,
      popoverMounted,
      popoverListenerAdded,
      placement,
      iid,
      title,
      groupPath,
      projectPath,
      namespacePath,
      milestone,
      iteration,
    } = popoverTarget.dataset;

    // No `data-reference-type` attribute present
    if (!referenceType) return;

    // Popover already initialized
    if (popoverMounted || popoverListenerAdded) return;

    // Popover not yet mounted, initialize it
    popoverTarget.dataset.popoverListenerAdded = true;
    handleIssuablePopoverMount({
      target: popoverTarget,
      apolloProvider,
      referenceType,
      placement,
      namespacePath: namespacePath || groupPath || projectPath,
      iid,
      title,
      milestone,
      iteration,
      innerText: popoverTarget.innerText.trim(),
    });
  });
}
