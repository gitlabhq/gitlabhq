import Vue from 'vue';
import VueRouter from 'vue-router';
import VueApollo from 'vue-apollo';
import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { ROUTES } from '~/work_items/constants';

import { routes } from '~/work_items/router/routes';

import { subscribeWithLimitEnforce } from 'ee_else_ce/work_items/list/utils';

import namespaceSavedViewQuery from '~/work_items/graphql/namespace_saved_view.query.graphql';

import WorkItemsSavedViewsLimitWarningModal from '~/work_items/list/components/work_items_saved_views_limit_warning_modal.vue';

import { exampleSavedViewResponse } from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('ee_else_ce/work_items/list/utils', () => ({
  ...jest.requireActual('ee_else_ce/work_items/list/utils'),
  subscribeWithLimitEnforce: jest.fn().mockResolvedValue(true),
}));

Vue.use(VueRouter);
Vue.use(VueApollo);

/** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
let wrapper;
let router;

const findModal = () => wrapper.findComponent(GlModal);

const fullPath = 'gitlab-org/gitlab';

const defaultSavedViewQueryHandler = jest.fn().mockResolvedValue(exampleSavedViewResponse);

const MockComponent = {};

const createComponent = async ({
  props = {},
  savedViewQueryHandler = defaultSavedViewQueryHandler,
} = {}) => {
  router = new VueRouter({
    mode: 'history',
    routes: [
      { name: 'base', path: '/', component: MockComponent },

      ...routes({ fullPath: '/work_items' }),
    ],
  });

  const apolloProvider = createMockApollo([[namespaceSavedViewQuery, savedViewQueryHandler]]);

  wrapper = shallowMountExtended(WorkItemsSavedViewsLimitWarningModal, {
    router,
    apolloProvider,
    provide: {
      subscribedSavedViewLimit: 5,
    },
    propsData: {
      show: true,
      fullPath,
      viewId: 'gid://gitlab/WorkItems::SavedViews::SavedView/3',
      ...props,
    },
    stubs: {
      GlSprintf,
    },
  });

  await router.push({ name: ROUTES.index, params: { type: 'work_items' } });

  await waitForPromises();
};

describe('WorkItemsSavedViewsLimitWarningModal', () => {
  describe('rendering', () => {
    it('shows the modal when the show prop is true', async () => {
      await createComponent();

      expect(findModal().props('visible')).toBe(true);
    });

    it('displays the correct text in the body', async () => {
      await createComponent();

      const textContent = findModal().text();
      expect(textContent).toContain(
        'You have reached the maximum number of views in your list. If you add this view, the last view currently in your list will be removed (not deleted). Learn more about view limits.',
      );
      expect(textContent).toContain(
        'Note: removed views can be added back by going to + Add view > Browse views',
      );
    });

    it('displays the correct title', async () => {
      await createComponent();

      expect(findModal().props('title')).toBe('Add Current sprint 3 view?');
    });

    it('displays an "Add view" and "Cancel" button', async () => {
      await createComponent();

      const modal = findModal();

      const primary = modal.props('actionPrimary');
      const cancel = modal.props('actionCancel');

      expect(primary.text).toBe('Add view');
      expect(cancel.text).toBe('Cancel');
    });
  });

  describe('closing the modal', () => {
    it('emits the hide event when the modal is closed', async () => {
      await createComponent();

      expect(wrapper.emitted('hide')).toBeUndefined();

      findModal().vm.$emit('hide');

      expect(wrapper.emitted('hide')).toBeDefined();
    });

    it('resets the route query when closed', async () => {
      await createComponent();
      await router.replace({
        query: { sv_limit_id: 'gid://gitlab/WorkItems::SavedViews::SavedView/3' },
      });

      expect(window.location.search).toContain('sv_limit_id');

      findModal().vm.$emit('hide');

      await waitForPromises();

      expect(window.location.search).not.toContain('sv_limit_id');
    });
  });

  describe('adding the view', () => {
    it('calls the subscribeWithLimitEnforce function when "Add view" is clicked', async () => {
      await createComponent();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });

      expect(subscribeWithLimitEnforce).toHaveBeenCalled();
    });

    it('navigates to the new view once subscription is complete', async () => {
      await createComponent();

      findModal().vm.$emit('primary', { preventDefault: jest.fn() });

      await waitForPromises();

      expect(window.location.pathname).toBe('/work_items/views/3');
    });
  });
});
