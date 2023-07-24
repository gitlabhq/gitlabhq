import IndexComponent from './pages/index.vue';
import NewComponent from './pages/new.vue';

export default [
  {
    path: '/',
    component: IndexComponent,
  },
  {
    path: '/new',
    component: NewComponent,
  },
];
