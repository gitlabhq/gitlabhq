import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from './constants';
import AchievementsForm from './components/achievements_form.vue';

export default [
  {
    name: INDEX_ROUTE_NAME,
    path: '/',
  },
  {
    name: NEW_ROUTE_NAME,
    path: '/new',
    component: AchievementsForm,
  },
  {
    name: EDIT_ROUTE_NAME,
    path: '/:id/edit',
  },
];
