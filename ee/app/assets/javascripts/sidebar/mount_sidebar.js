import Vue from 'vue';
import * as CEMountSidebar from '~/sidebar/mount_sidebar';
import sidebarWeight from './components/weight/sidebar_weight.vue';
import SidebarItemEpic from './components/sidebar_item_epic.vue';

function mountWeightComponent(mediator) {
  const el = document.querySelector('.js-sidebar-weight-entry-point');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      sidebarWeight,
    },
    render: createElement => createElement('sidebar-weight', {
      props: {
        mediator,
      },
    }),
  });
}

function mountEpic() {
  const el = document.querySelector('#js-vue-sidebar-item-epic');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      SidebarItemEpic,
    },
    render: createElement => createElement('sidebar-item-epic', {}),
  });
}

export default function mountSidebar(mediator) {
  CEMountSidebar.mountSidebar(mediator);
  mountWeightComponent(mediator);
  mountEpic();
}
