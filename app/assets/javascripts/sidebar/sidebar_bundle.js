import Mediator from './sidebar_mediator';
import { mountSidebar, getSidebarOptions } from './mount_sidebar';

function domContentLoaded() {
  const mediator = new Mediator(getSidebarOptions());
  mediator.fetch();

  mountSidebar(mediator);
}

document.addEventListener('DOMContentLoaded', domContentLoaded);

export default domContentLoaded;
