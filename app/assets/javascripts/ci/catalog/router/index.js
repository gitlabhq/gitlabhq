import Vue from 'vue';
import VueRouter from 'vue-router';
import { createRoutes } from './routes';

Vue.use(VueRouter);

export const createRouter = (base, listComponent) => {
  return new VueRouter({
    base,
    mode: 'history',
    routes: createRoutes(listComponent),
  });
};
