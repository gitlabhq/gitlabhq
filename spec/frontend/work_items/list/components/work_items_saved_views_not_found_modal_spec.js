import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { ROUTES } from '~/work_items/constants';

import { routes } from '~/work_items/router/routes';

import WorkItemsSavedViewsNotFoundModal from '~/work_items/list/components/work_items_saved_views_not_found_modal.vue';

Vue.use(VueRouter);
Vue.use(VueApollo);

/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;
let router;

const findModal = () => wrapper.findComponent(GlModal);

const MockComponent = {};

const createComponent = async () => {
  router = new VueRouter({
    mode: 'history',
    routes: [
      { name: 'base', path: '/', component: MockComponent },

      ...routes({ fullPath: '/work_items' }),
    ],
  });

  wrapper = shallowMountExtended(WorkItemsSavedViewsNotFoundModal, {
    router,
    provide: {
      subscribedSavedViewLimit: 5,
    },
    propsData: {
      show: true,
    },
    stubs: {
      GlSprintf,
    },
  });

  await router.push({ name: ROUTES.index, params: { type: 'work_items' } });

  await waitForPromises();
};

describe('WorkItemsSavedViewsNotFoundModal', () => {
  describe('rendering', () => {
    it('shows the modal when the show prop is true', async () => {
      await createComponent();

      expect(findModal().props('visible')).toBe(true);
    });

    it('displays the correct text in the body', async () => {
      await createComponent();

      const textContent = findModal().text();
      expect(textContent).toContain(
        'This view either no longer exists or you do not have access to it. Make sure the view exists and the visibility is set to Shared if you are not the owner.',
      );
    });

    it('displays the correct title', async () => {
      await createComponent();

      expect(findModal().props('title')).toBe('View not found');
    });

    it('displays only a "Dismiss" button', async () => {
      await createComponent();

      expect(findModal().props('actionPrimary').text).toBe('Dismiss');
    });
  });
  describe('dismissing the modal', () => {
    it('emits the hide event when the modal is closed', async () => {
      await createComponent();

      expect(wrapper.emitted('hide')).toBeUndefined();

      findModal().vm.$emit('hide');

      expect(wrapper.emitted('hide')).toBeDefined();
    });

    it('resets the route query when closed', async () => {
      await createComponent();
      await router.replace({ query: { sv_not_found: true } });

      expect(window.location.search).toContain('sv_not_found');

      findModal().vm.$emit('hide');

      await waitForPromises();

      expect(window.location.search).not.toContain('sv_not_found');
    });
  });
});
