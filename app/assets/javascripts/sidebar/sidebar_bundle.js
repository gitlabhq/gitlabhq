import { mountSidebar, getSidebarOptions } from './mount_sidebar';
import Mediator from './sidebar_mediator';

export default () => {
  const mediator = new Mediator(getSidebarOptions());
  mediator.fetch();

  mountSidebar(mediator);
};
