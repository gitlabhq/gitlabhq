import Mediator from './sidebar_mediator';
import { mountSidebar, getSidebarOptions } from './mount_sidebar';

export default () => {
  const mediator = new Mediator(getSidebarOptions());
  mediator.fetch();

  mountSidebar(mediator);
};
