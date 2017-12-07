import { getSidebarOptions } from '~/sidebar/mount_sidebar';
import Mediator from './sidebar_mediator';
import mountSidebar from './mount_sidebar';

function domContentLoaded() {
  const mediator = new Mediator(getSidebarOptions());
  mediator.fetch();

  mountSidebar(mediator);
}

document.addEventListener('DOMContentLoaded', domContentLoaded);

export default domContentLoaded;
