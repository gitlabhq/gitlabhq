import IndexComponent from './pages/index.vue';

import EditComponent from './pages/edit.vue';

export default [
  {
    path: '/',
    component: IndexComponent,
  },
  {
    name: 'edit',
    path: '/:id',
    component: EditComponent,
  },
];
