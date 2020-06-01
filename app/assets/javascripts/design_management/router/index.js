import $ from 'jquery';
import Vue from 'vue';
import VueRouter from 'vue-router';
import routes from './routes';
import { DESIGN_ROUTE_NAME } from './constants';
import { getPageLayoutElement } from '~/design_management/utils/design_management_utils';
import { DESIGN_DETAIL_LAYOUT_CLASSLIST } from '../constants';

Vue.use(VueRouter);

export default function createRouter(base) {
  const router = new VueRouter({
    base,
    mode: 'history',
    routes,
  });
  const pageEl = getPageLayoutElement();

  router.beforeEach(({ meta: { el }, name }, _, next) => {
    $(`#${el}`).tab('show');

    // apply a fullscreen layout style in Design View (a.k.a design detail)
    if (pageEl) {
      if (name === DESIGN_ROUTE_NAME) {
        pageEl.classList.add(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
      } else {
        pageEl.classList.remove(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
      }
    }

    next();
  });

  return router;
}
