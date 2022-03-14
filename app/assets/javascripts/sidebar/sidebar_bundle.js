import { mountSidebar, getSidebarOptions } from 'ee_else_ce/sidebar/mount_sidebar';
import Mediator from './sidebar_mediator';

export default (store) => {
  const mediator = new Mediator(getSidebarOptions());
  mediator
    .fetch()
    .then(() => {
      if (window.gon?.features?.mrAttentionRequests) {
        return import('~/attention_requests');
      }

      return null;
    })
    .then((module) => module?.initSideNavPopover())
    .catch(() => {});

  mountSidebar(mediator, store);
};
