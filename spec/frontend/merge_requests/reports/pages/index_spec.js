import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MergeRequestReportsIndexPage from '~/merge_requests/reports/pages/index.vue';

Vue.use(VueRouter);

const DEFAULT_MR_PROPS = { id: 1 };

const ReportWidgetContainerStub = {
  name: 'ReportWidgetContainer',
  props: ['mr'],
  template: '<div></div>',
};

describe('MergeRequestReportsIndexPage', () => {
  let wrapper;
  let router;

  const createComponent = async ({ mr = DEFAULT_MR_PROPS, route = '/' } = {}) => {
    router = new VueRouter({
      mode: 'abstract',
      routes: [{ path: '/:report?', name: 'reports', component: MergeRequestReportsIndexPage }],
    });
    await router.push(route);

    wrapper = shallowMountExtended(MergeRequestReportsIndexPage, {
      router,
      propsData: { mr },
      stubs: {
        ReportWidgetContainer: ReportWidgetContainerStub,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findReportWidgetContainer = () => wrapper.findComponent(ReportWidgetContainerStub);

  describe('loading state', () => {
    beforeEach(() => createComponent({ mr: null }));

    it('shows loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render any report view', () => {
      expect(findReportWidgetContainer().exists()).toBe(false);
    });
  });

  describe('default report view', () => {
    beforeEach(() => createComponent());

    it('does not show loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders ReportWidgetContainer with mr prop', async () => {
      await waitForPromises();
      expect(findReportWidgetContainer().props('mr')).toEqual(DEFAULT_MR_PROPS);
    });
  });
});
