import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import getDesignQuery from '~/work_items/components/design_management/graphql/design_details.query.graphql';
import getLocalDesignQuery from '~/work_items/components/design_management/graphql/local_design.query.graphql';
import archiveDesignMutation from '~/work_items/components/design_management/graphql/archive_design.mutation.graphql';
import DesignDetails from '~/work_items/components/design_management/design_preview/design_details.vue';
import DesignPresentation from '~/work_items/components/design_management/design_preview/design_presentation.vue';
import DesignToolbar from '~/work_items/components/design_management/design_preview/design_toolbar.vue';
import DesignSidebar from '~/work_items/components/design_management/design_preview/design_sidebar.vue';
import DesignScaler from '~/work_items/components/design_management/design_preview/design_scaler.vue';
import * as utils from '~/work_items/components/design_management/utils';
import { updateWorkItemDesignCurrentTodosWidget } from '~/work_items/components/design_management/cache_updates';
import {
  DESIGN_DETAIL_LAYOUT_CLASSLIST,
  DESIGN_NOT_FOUND_ERROR,
  DESIGN_SINGLE_ARCHIVE_ERROR,
} from '~/work_items/components/design_management/constants';
import { getDesignResponse, mockDesign, mockArchiveDesignMutationResponse } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/work_items/components/design_management/cache_updates', () => ({
  updateWorkItemDesignCurrentTodosWidget: jest.fn(),
}));
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
  const findDesignScaler = () => wrapper.findComponent(DesignScaler);

  const getDesignQueryHandler = jest.fn().mockResolvedValue(getDesignResponse);
  const archiveDesignSuccessMutationHandler = jest
    .fn()
    .mockResolvedValue(mockArchiveDesignMutationResponse);
  const archiveDesignMutationError = jest.fn().mockRejectedValue(new Error('Mutation failed'));
  const error = new Error('ruh roh some error');
  const errorQueryHandler = jest.fn().mockRejectedValue(error);

  function createComponent({
    queryHandler = getDesignQueryHandler,
    archiveDesignMutationHandler = archiveDesignSuccessMutationHandler,
    routeArg = MOCK_ROUTE,
    data = {},
  } = {}) {
    wrapper = shallowMountExtended(DesignDetails, {
      apolloProvider: createMockApollo([
        [getDesignQuery, queryHandler],
        [archiveDesignMutation, archiveDesignMutationHandler],
      ]),
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

    it('renders `DesignScaler` component', () => {
      expect(findDesignScaler().exists()).toBe(true);
    });

    it('archives a design', async () => {
      findDesignToolbar().vm.$emit('archive-design');
      await waitForPromises();

      expect(archiveDesignSuccessMutationHandler).toHaveBeenCalled();
    });

    it('throws error if archive a design query fails', async () => {
      createComponent({ archiveDesignMutationHandler: archiveDesignMutationError });

      findDesignToolbar().vm.$emit('archive-design');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: DESIGN_SINGLE_ARCHIVE_ERROR });
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

  describe('design toolbar', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders with correct data', () => {
      const { design, currentUserDesignTodos, designFilename } = findDesignToolbar().props();

      expect(design).toEqual(mockDesign);
      expect(currentUserDesignTodos).toEqual([]);
      expect(designFilename).toEqual(MOCK_ROUTE.params.id);
    });

    it('closes sidebar on toggle', async () => {
      expect(findDesignSidebar().props('isOpen')).toBe(true);

      findDesignToolbar().vm.$emit('toggle-sidebar');
      await nextTick();

      expect(findDesignSidebar().props('isOpen')).toBe(false);
    });

    it('updates cache when todos are updated', () => {
      findDesignToolbar().vm.$emit('todosUpdated', { cache: expect.anything(), todos: [] });

      expect(updateWorkItemDesignCurrentTodosWidget).toHaveBeenCalledWith({
        store: expect.anything(),
        todos: [],
        query: {
          query: getLocalDesignQuery,
          variables: {
            filenames: [MOCK_ROUTE.params.id],
            atVersion: null,
          },
        },
      });
    });
  });
});
