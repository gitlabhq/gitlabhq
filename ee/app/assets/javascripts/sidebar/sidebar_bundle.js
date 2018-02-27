import { getSidebarOptions } from '~/sidebar/mount_sidebar';
import Mediator from './sidebar_mediator';
import mountSidebar from './mount_sidebar';

export default () => {
  const mediator = new Mediator(getSidebarOptions());
  mediator.fetch();

  mountSidebar(mediator);
};
