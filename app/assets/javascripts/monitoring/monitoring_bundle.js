import mountComponent from '~/vue_shared/mount_vue_component';
import Dashboard from './components/dashboard.vue';

export default () => mountComponent(Dashboard, '#prometheus-graphs');
