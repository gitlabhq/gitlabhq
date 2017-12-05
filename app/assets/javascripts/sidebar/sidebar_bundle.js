import mountSidebarEE from 'ee/sidebar/mount_sidebar';
import Mediator from 'ee/sidebar/sidebar_mediator';
import mountSidebar from './mount_sidebar';

function domContentLoaded() {
  const sidebarOptions = JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);
  const mediator = new Mediator(sidebarOptions);
  mediator.fetch();

  mountSidebar(mediator);
  mountSidebarEE(mediator);
}

document.addEventListener('DOMContentLoaded', domContentLoaded);

export default domContentLoaded;
