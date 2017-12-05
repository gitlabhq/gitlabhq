<<<<<<< HEAD
import mountSidebarEE from 'ee/sidebar/mount_sidebar';
import Mediator from 'ee/sidebar/sidebar_mediator';
=======
import Mediator from './sidebar_mediator';
>>>>>>> upstream/master
import mountSidebar from './mount_sidebar';

function domContentLoaded() {
  const sidebarOptions = JSON.parse(document.querySelector('.js-sidebar-options').innerHTML);
  const mediator = new Mediator(sidebarOptions);
  mediator.fetch();

  mountSidebar(mediator);
<<<<<<< HEAD
  mountSidebarEE(mediator);
=======
>>>>>>> upstream/master
}

document.addEventListener('DOMContentLoaded', domContentLoaded);

export default domContentLoaded;
