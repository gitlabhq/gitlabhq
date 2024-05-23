import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import getDesignQuery from '~/work_items/components/design_management/graphql/design_details.query.graphql';
import DesignDetails from '~/work_items/components/design_management/design_preview/design_details.vue';
import DesignPresentation from '~/work_items/components/design_management/design_preview/design_presentation.vue';
import DesignToolbar from '~/work_items/components/design_management/design_preview/design_toolbar.vue';
import DesignSidebar from '~/work_items/components/design_management/design_preview/design_sidebar.vue';
import { DESIGN_NOT_FOUND_ERROR } from '~/work_items/components/design_management/error_messages';
import * as utils from '~/work_items/components/design_management/utils';
import { DESIGN_DETAIL_LAYOUT_CLASSLIST } from '~/work_items/components/design_management/constants';

import { getDesignResponse } from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const MOCK_ROUTE = {
  path: '/work_items/1/designs/Screenshot_from_2024-03-28_10-24-43.png',
  query: {},
  params: {
    id: 'image_name.png',
  },
};

const mockPageLayoutElement = {
  classList: {
    add: jest.fn(),
    remove: jest.fn(),
  },
};

describe('DesignDetails', () => {
  let wrapper;
  const workItemIid = '1';
  const routerPushMock = jest.fn();

  const findDesignPresentation = () => wrapper.findComponent(DesignPresentation);
  const findDesignToolbar = () => wrapper.findComponent(DesignToolbar);
  const findDesignSidebar = () => wrapper.findComponent(DesignSidebar);

  const getDesignQueryHandler = jest.fn().mockResolvedValue(getDesignResponse);
  const error = new Error('ruh roh some error');
  const errorQueryHandler = jest.fn().mockRejectedValue(error);

  function createComponent({
    queryHandler = getDesignQueryHandler,
    routeArg = MOCK_ROUTE,
    data = {},
  } = {}) {
    wrapper = shallowMountExtended(DesignDetails, {
      apolloProvider: createMockApollo([[getDesignQuery, queryHandler]]),
      data() {
        return data;
      },
      propsData: {
        iid: workItemIid,
      },
      mocks: {
        $route: routeArg,
        $router: { push: routerPushMock },
      },
      provide: {
        fullPath: 'gitlab-org/gitlab-shell',
      },
      stubs: {
        RouterView: true,
      },
    });
  }

  it('sets loading state', () => {
    createComponent();

    expect(findDesignPresentation().props('isLoading')).toBe(true);
    expect(findDesignToolbar().props('isLoading')).toBe(true);
    expect(findDesignSidebar().props('isLoading')).toBe(true);
  });

  describe('when loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('calls get design query', () => {
      expect(getDesignQueryHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab-shell',
        iid: workItemIid,
        filenames: ['image_name.png'],
        atVersion: null,
      });
    });

    it('closes sidebar on toggle', async () => {
      expect(findDesignSidebar().props('isOpen')).toBe(true);

      findDesignToolbar().vm.$emit('toggle-sidebar');
      await nextTick();

      expect(findDesignSidebar().props('isOpen')).toBe(false);
    });
  });

  describe('when query fails', () => {
    beforeEach(async () => {
      createComponent({
        queryHandler: errorQueryHandler,
      });
      await waitForPromises();
    });

    it('createAlert has been called', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: DESIGN_NOT_FOUND_ERROR });
    });
  });

  describe('when navigating to component', () => {
    it('applies fullscreen layout class', () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent();

      DesignDetails.beforeRouteEnter.call(wrapper.vm, {}, {}, jest.fn());

      expect(mockPageLayoutElement.classList.add).toHaveBeenCalledTimes(1);
      expect(mockPageLayoutElement.classList.add).toHaveBeenCalledWith(
        ...DESIGN_DETAIL_LAYOUT_CLASSLIST,
      );
    });
  });

  describe('when navigating within the component', () => {
    it('`scale` prop of DesignPresentation component is 1', async () => {
      createComponent({ data: { scale: 2 } });

      await nextTick();
      expect(findDesignPresentation().props('scale')).toBe(2);

      DesignDetails.beforeRouteUpdate.call(wrapper.vm, {}, {}, jest.fn());
      await nextTick();

      expect(findDesignPresentation().props('scale')).toBe(1);
    });
  });

  describe('when navigating away from component', () => {
    it('removes fullscreen layout class', () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent();

      DesignDetails.beforeRouteLeave.call(wrapper.vm, {}, {}, jest.fn());

      expect(mockPageLayoutElement.classList.remove).toHaveBeenCalledTimes(1);
      expect(mockPageLayoutElement.classList.remove).toHaveBeenCalledWith(
        ...DESIGN_DETAIL_LAYOUT_CLASSLIST,
      );
    });
  });
});
