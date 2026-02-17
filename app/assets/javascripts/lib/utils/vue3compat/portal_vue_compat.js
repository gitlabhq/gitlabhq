import PortalVueDefault, {
  Portal as PortalVue2,
  PortalTarget as PortalTargetVue2,
  MountingPortal as MountingPortalVue2,
  Wormhole as WormholeVue2,
} from 'portal-vue/dist/portal-vue.esm';
import {
  Portal as PortalVue3,
  PortalTarget as PortalTargetVue3,
  MountingPortal as MountingPortalVue3,
} from 'portal-vue-vue3-impl';

function isVue3Instance(vm) {
  return Boolean(vm.$);
}

export const Portal = {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'Portal',
  functional: true,
  render(h, { data, children, parent }) {
    const Component = isVue3Instance(parent) ? PortalVue3 : PortalVue2;
    return h(Component, data, children);
  },
};

export const PortalTarget = {
  name: 'PortalTarget',
  functional: true,
  render(h, { data, children, parent }) {
    const Component = isVue3Instance(parent) ? PortalTargetVue3 : PortalTargetVue2;
    return h(Component, data, children);
  },
};

export const MountingPortal = {
  name: 'MountingPortal',
  functional: true,
  render(h, { data, children, parent }) {
    const Component = isVue3Instance(parent) ? MountingPortalVue3 : MountingPortalVue2;
    return h(Component, data, children);
  },
};

export const Wormhole = WormholeVue2;

export default PortalVueDefault;
