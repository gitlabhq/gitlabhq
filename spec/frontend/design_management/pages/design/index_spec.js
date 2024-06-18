import { GlAlert } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo, { ApolloMutation } from 'vue-apollo';
import VueRouter from 'vue-router';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Api from '~/api';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import DesignPresentation from '~/design_management/components/design_presentation.vue';
import DesignSidebar from '~/design_management/components/design_sidebar.vue';
import DesignDestroyer from '~/design_management/components/design_destroyer.vue';
import Toolbar from '~/design_management/components/toolbar/index.vue';
import { DESIGN_DETAIL_LAYOUT_CLASSLIST } from '~/design_management/constants';
import getDesignQuery from '~/design_management/graphql/queries/get_design.query.graphql';
import getDesignListQuery from 'shared_queries/design_management/get_design_list.query.graphql';
import DesignIndex from '~/design_management/pages/design/index.vue';
import createRouter from '~/design_management/router';
import { DESIGNS_ROUTE_NAME, DESIGN_ROUTE_NAME } from '~/design_management/router/constants';
import * as utils from '~/design_management/utils/design_management_utils';
import {
  DESIGN_NOT_FOUND_ERROR,
  DESIGN_VERSION_NOT_EXIST_ERROR,
} from '~/design_management/utils/error_messages';
import {
  DESIGN_TRACKING_PAGE_NAME,
  DESIGN_SNOWPLOW_EVENT_TYPES,
  DESIGN_SERVICE_PING_EVENT_TYPES,
} from '~/design_management/utils/tracking';
import { createAlert } from '~/alert';
import * as cacheUpdate from '~/design_management/utils/cache_update';
import { stubComponent } from 'helpers/stub_component';

import mockAllVersions from '../../mock_data/all_versions';
import design from '../../mock_data/design';
import mockResponseWithDesigns from '../../mock_data/designs';
import mockResponseNoDesigns from '../../mock_data/no_designs';
import { mockCreateImageNoteDiffResponse } from '../../mock_data/apollo_mock';

jest.mock('~/alert');
jest.mock('~/api.js');
jest.mock('~/design_management/utils/cache_update');

Vue.use(VueApollo);
Vue.use(VueRouter);

const mockPageLayoutElement = {
  classList: {
    add: jest.fn(),
    remove: jest.fn(),
  },
};

const DesignSidebarStub = stubComponent(DesignSidebar, {
  template: '<div><slot name="reply-form"></slot></div>',
});

const mockAllVersionsResponse = {
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      issue: {
        __typename: 'Issue',
        id: 'gid://gitlab/Issue/1',
        designCollection: {
          __typename: 'DesignCollection',
          copyState: 'READY',
          versions: { __typename: 'DesignVersionConnection', nodes: mockAllVersions },
          designs: {
            __typename: 'DesignConnection',
            nodes: [],
          },
        },
      },
    },
  },
};

describe('Design management design index page', () => {
  let wrapper;
  let router;
  let mockApollo;

  const findDesignReplyForm = () => wrapper.findComponent(DesignReplyForm);
  const findSidebar = () => wrapper.findComponent(DesignSidebar);
  const findDesignPresentation = () => wrapper.findComponent(DesignPresentation);
  const findToolbar = () => wrapper.findComponent(Toolbar);

  const updateActiveDiscussionResolver = jest.fn();
  const getDesignQueryHandler = jest.fn().mockResolvedValue({ data: mockResponseWithDesigns });
  const allVersionsQueryHandler = jest.fn().mockResolvedValue(mockAllVersionsResponse);
  const error = new Error('ruh roh some error');
  const errorQueryHandler = jest.fn().mockRejectedValue(error);

  const createComponent = ({
    data = {},
    initialRouteOptions = {},
    provide = {},
    stubs = { DesignSidebar: DesignSidebarStub },
    designQueryHandler = getDesignQueryHandler,
  } = {}) => {
    router = createRouter();

    router.push({ name: DESIGN_ROUTE_NAME, params: { id: design.id }, ...initialRouteOptions });

    mockApollo = createMockApollo(
      [
        [getDesignQuery, designQueryHandler],
        [getDesignListQuery, allVersionsQueryHandler],
      ],
      {
        Mutation: {
          updateActiveDiscussion: updateActiveDiscussionResolver,
        },
      },
    );

    wrapper = shallowMountExtended(DesignIndex, {
      propsData: { id: '1' },
      apolloProvider: mockApollo,
      stubs: {
        ...stubs,
        RouterLink: true,
        DesignDestroyer,
        ApolloMutation,
      },
      provide: {
        issueIid: '1',
        projectPath: 'project-path',
        ...provide,
      },
      data() {
        return {
          activeDiscussion: {
            id: null,
            source: null,
          },
          ...data,
        };
      },
      router,
    });
  };

  afterEach(() => {
    mockApollo = null;
  });

  it('sets loading state', () => {
    createComponent();

    expect(wrapper.findComponent(DesignPresentation).props('isLoading')).toBe(true);
    expect(wrapper.findComponent(DesignSidebar).props('isLoading')).toBe(true);
  });

  describe('when loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders design index', () => {
      expect(wrapper.element).toMatchSnapshot();
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });

    it('passes correct props to sidebar component', () => {
      expect(findSidebar().props()).toEqual({
        design: expect.any(Object),
        markdownPreviewPath: '/project-path/-/preview_markdown?target_type=Issue',
        resolvedDiscussionsExpanded: false,
        isLoading: false,
        isOpen: true,
        designVariables: {
          fullPath: 'project-path',
          iid: '1',
          filenames: ['gid:/gitlab/Design/1'],
          atVersion: null,
        },
      });
    });

    it('opens a new discussion form', async () => {
      findDesignPresentation().vm.$emit('openCommentForm', { x: 0, y: 0 });
      expect(findSidebar().props('isOpen')).toBe(true);

      await nextTick();
      expect(findDesignReplyForm().exists()).toBe(true);
    });

    it('closes sidebar and disables commenting on toggle', async () => {
      expect(findDesignPresentation().props('disableCommenting')).toBe(false);
      expect(findSidebar().props('isOpen')).toBe(true);

      findToolbar().vm.$emit('toggle-sidebar');
      await nextTick();

      expect(findDesignPresentation().props('disableCommenting')).toBe(true);
      expect(findSidebar().props('isOpen')).toBe(false);
    });
  });

  describe('when annotating', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
      findDesignPresentation().vm.$emit('openCommentForm', { x: 0, y: 0 });
    });

    it('sends a update and closes the form when mutation is completed', async () => {
      const addImageDiffNoteToStore = jest.spyOn(cacheUpdate, 'updateStoreAfterAddImageDiffNote');

      const mockDesignVariables = {
        fullPath: 'project-path',
        iid: '1',
        filenames: ['gid:/gitlab/Design/1'],
        atVersion: null,
      };

      findDesignReplyForm().vm.$emit('note-submit-complete', mockCreateImageNoteDiffResponse);

      await nextTick();
      expect(addImageDiffNoteToStore).toHaveBeenCalledWith(
        expect.any(Object),
        mockCreateImageNoteDiffResponse.data.createImageDiffNote,
        getDesignQuery,
        mockDesignVariables,
      );
      expect(findDesignReplyForm().exists()).toBe(false);
    });

    it('closes the form and clears the comment on canceling form', async () => {
      findDesignReplyForm().vm.$emit('cancel-form');

      await nextTick();
      expect(findDesignReplyForm().exists()).toBe(false);
    });
  });

  describe('when navigating to component', () => {
    it('applies fullscreen layout class', () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent();

      expect(mockPageLayoutElement.classList.add).toHaveBeenCalledTimes(1);
      expect(mockPageLayoutElement.classList.add).toHaveBeenCalledWith(
        ...DESIGN_DETAIL_LAYOUT_CLASSLIST,
      );
    });
  });

  describe('when navigating within the component', () => {
    it('`scale` prop of DesignPresentation component is 1', async () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent({ data: { scale: 2 } });

      await nextTick();
      expect(findDesignPresentation().props('scale')).toBe(2);

      DesignIndex.beforeRouteUpdate.call(wrapper.vm, {}, {}, jest.fn());
      await nextTick();

      expect(findDesignPresentation().props('scale')).toBe(1);
    });
  });

  describe('when navigating away from component', () => {
    it('removes fullscreen layout class', () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent();

      wrapper.vm.$options.beforeRouteLeave[0].call(wrapper.vm, {}, {}, jest.fn());

      expect(mockPageLayoutElement.classList.remove).toHaveBeenCalledTimes(1);
      expect(mockPageLayoutElement.classList.remove).toHaveBeenCalledWith(
        ...DESIGN_DETAIL_LAYOUT_CLASSLIST,
      );
    });
  });

  describe('with error', () => {
    beforeEach(async () => {
      createComponent({
        designQueryHandler: errorQueryHandler,
      });
      router.push = jest.fn();
      await waitForPromises();
    });

    it('createAlert has been called', () => {
      expect(createAlert).toHaveBeenCalledWith({ message: DESIGN_NOT_FOUND_ERROR });
    });
  });

  describe('onDesignQueryResult', () => {
    describe('with no designs', () => {
      it('redirects to /designs', async () => {
        createComponent();
        router.push = jest.fn();

        wrapper.vm.onDesignQueryResult({ data: mockResponseNoDesigns, loading: false });
        await nextTick();
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({ message: DESIGN_NOT_FOUND_ERROR });
        expect(router.push).toHaveBeenCalledTimes(1);
        expect(router.push).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
      });
    });

    describe('when no design exists for given version', () => {
      it('redirects to /designs', async () => {
        createComponent();
        // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
        // eslint-disable-next-line no-restricted-syntax
        wrapper.setData({
          allVersions: mockAllVersions,
        });

        // attempt to query for a version of the design that doesn't exist
        router.push({ query: { version: '999' } });
        router.push = jest.fn();

        wrapper.vm.onDesignQueryResult({ data: mockResponseWithDesigns, loading: false });
        await nextTick();
        expect(createAlert).toHaveBeenCalledTimes(1);
        expect(createAlert).toHaveBeenCalledWith({ message: DESIGN_VERSION_NOT_EXIST_ERROR });
        expect(router.push).toHaveBeenCalledTimes(1);
        expect(router.push).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
      });
    });
  });

  describe('when hash present in current route', () => {
    beforeEach(async () => {
      createComponent({
        initialRouteOptions: { hash: '#note_123' },
      });
      await waitForPromises();
    });

    it('calls updateActiveDiscussion mutation', () => {
      expect(updateActiveDiscussionResolver).toHaveBeenCalledTimes(1);
      expect(updateActiveDiscussionResolver).toHaveBeenCalledWith(
        {},
        expect.objectContaining({
          id: 'gid://gitlab/DiffNote/123',
          source: 'url',
        }),
        expect.any(Object),
        expect.any(Object),
      );
    });
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(async () => {
      trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
      createComponent();
      await waitForPromises();
    });

    afterEach(() => {
      unmockTracking();
    });

    describe('on mount', () => {
      it('tracks design view in snowplow', () => {
        expect(trackingSpy).toHaveBeenCalledTimes(1);
        expect(trackingSpy).toHaveBeenCalledWith(
          DESIGN_TRACKING_PAGE_NAME,
          DESIGN_SNOWPLOW_EVENT_TYPES.VIEW_DESIGN,
          {
            context: {
              data: {
                'design-collection-owner': 'issue',
                'design-is-current-version': true,
                'design-version-number': 1,
                'internal-object-referrer': 'issue-design-collection',
              },
              schema: 'iglu:com.gitlab/design_management_context/jsonschema/1-0-0',
            },
            label: DESIGN_SNOWPLOW_EVENT_TYPES.VIEW_DESIGN,
          },
        );
      });

      it('tracks design view service ping', () => {
        expect(Api.trackRedisHllUserEvent).toHaveBeenCalledTimes(1);
        expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(
          DESIGN_SERVICE_PING_EVENT_TYPES.DESIGN_ACTION,
        );
      });
    });
  });
});
