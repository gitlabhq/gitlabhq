import { mountSidebar, getSidebarOptions } from 'ee_else_ce/sidebar/mount_sidebar';
import Mediator from './sidebar_mediator';

export default (store, pinia) => {
  const mediator = new Mediator(getSidebarOptions());
  mediator.fetch();

  mountSidebar(mediator, store, pinia);
};
