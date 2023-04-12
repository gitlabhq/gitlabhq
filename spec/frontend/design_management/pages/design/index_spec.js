import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import Api from '~/api';
import DesignPresentation from '~/design_management/components/design_presentation.vue';
import DesignSidebar from '~/design_management/components/design_sidebar.vue';
import { DESIGN_DETAIL_LAYOUT_CLASSLIST } from '~/design_management/constants';
import updateActiveDiscussion from '~/design_management/graphql/mutations/update_active_discussion.mutation.graphql';
import getDesignQuery from '~/design_management/graphql/queries/get_design.query.graphql';
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
import mockAllVersions from '../../mock_data/all_versions';
import design from '../../mock_data/design';
import mockProject from '../../mock_data/project';
import mockResponseWithDesigns from '../../mock_data/designs';
import mockResponseNoDesigns from '../../mock_data/no_designs';
import { mockCreateImageNoteDiffResponse } from '../../mock_data/apollo_mock';

jest.mock('~/alert');
jest.mock('~/api.js');

const focusInput = jest.fn();
const mockCacheObject = {
  readQuery: jest.fn().mockReturnValue(mockProject),
  writeQuery: jest.fn(),
};
const mutate = jest.fn().mockResolvedValue();
const mockPageLayoutElement = {
  classList: {
    add: jest.fn(),
    remove: jest.fn(),
  },
};
const DesignReplyForm = {
  template: '<div><textarea ref="textarea"></textarea></div>',
  methods: {
    focusInput,
  },
};
const mockDesignNoDiscussions = {
  ...design,
  discussions: {
    nodes: [],
  },
};

const annotationCoordinates = {
  x: 10,
  y: 10,
  width: 100,
  height: 100,
};

Vue.use(VueRouter);

describe('Design management design index page', () => {
  let wrapper;
  let router;

  const findDesignReplyForm = () => wrapper.findComponent(DesignReplyForm);
  const findSidebar = () => wrapper.findComponent(DesignSidebar);
  const findDesignPresentation = () => wrapper.findComponent(DesignPresentation);

  function createComponent(
    { loading = false } = {},
    {
      data = {},
      intialRouteOptions = {},
      provide = {},
      stubs = { DesignSidebar, DesignReplyForm },
    } = {},
  ) {
    const $apollo = {
      queries: {
        design: {
          loading,
        },
      },
      mutate,
      getClient() {
        return {
          cache: mockCacheObject,
        };
      },
    };

    router = createRouter();

    router.push({ name: DESIGN_ROUTE_NAME, params: { id: design.id }, ...intialRouteOptions });

    wrapper = shallowMount(DesignIndex, {
      propsData: { id: '1' },
      mocks: { $apollo },
      stubs,
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
  }

  describe('when navigating to component', () => {
    it('applies fullscreen layout class', () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent({}, { stubs: {} });

      expect(mockPageLayoutElement.classList.add).toHaveBeenCalledTimes(1);
      expect(mockPageLayoutElement.classList.add).toHaveBeenCalledWith(
        ...DESIGN_DETAIL_LAYOUT_CLASSLIST,
      );
    });
  });

  describe('when navigating within the component', () => {
    it('`scale` prop of DesignPresentation component is 1', async () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent({}, { data: { design, scale: 2 } });

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
      createComponent({ loading: true });

      wrapper.vm.$options.beforeRouteLeave[0].call(wrapper.vm, {}, {}, jest.fn());

      expect(mockPageLayoutElement.classList.remove).toHaveBeenCalledTimes(1);
      expect(mockPageLayoutElement.classList.remove).toHaveBeenCalledWith(
        ...DESIGN_DETAIL_LAYOUT_CLASSLIST,
      );
    });
  });

  it('sets loading state', () => {
    createComponent({ loading: true });

    expect(wrapper.findComponent(DesignPresentation).props('isLoading')).toBe(true);
    expect(wrapper.findComponent(DesignSidebar).props('isLoading')).toBe(true);
  });

  it('renders design index', () => {
    createComponent({ loading: false }, { data: { design } });

    expect(wrapper.element).toMatchSnapshot();
    expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
  });

  it('passes correct props to sidebar component', () => {
    createComponent({ loading: false }, { data: { design } });

    expect(findSidebar().props()).toEqual({
      design,
      markdownPreviewPath: '/project-path/preview_markdown?target_type=Issue',
      resolvedDiscussionsExpanded: false,
      isLoading: false,
    });
  });

  it('opens a new discussion form', async () => {
    createComponent(
      { loading: false },
      {
        data: {
          design,
        },
      },
    );

    findDesignPresentation().vm.$emit('openCommentForm', { x: 0, y: 0 });

    await nextTick();
    expect(findDesignReplyForm().exists()).toBe(true);
  });

  it('keeps new discussion form focused', () => {
    createComponent(
      { loading: false },
      {
        data: {
          design,
          annotationCoordinates,
        },
      },
    );

    findDesignPresentation().vm.$emit('openCommentForm', { x: 10, y: 10 });

    expect(focusInput).toHaveBeenCalled();
  });

  it('sends a update and closes the form when mutation is completed', async () => {
    createComponent(
      { loading: false },
      {
        data: {
          design,
          annotationCoordinates,
        },
      },
    );

    const addImageDiffNoteToStore = jest.spyOn(cacheUpdate, 'updateStoreAfterAddImageDiffNote');

    const mockDesignVariables = {
      fullPath: 'project-path',
      iid: '1',
      filenames: ['gid::/gitlab/Design/1'],
      atVersion: null,
    };

    findDesignReplyForm().vm.$emit('note-submit-complete', mockCreateImageNoteDiffResponse);

    await nextTick();
    expect(addImageDiffNoteToStore).toHaveBeenCalledWith(
      mockCacheObject,
      mockCreateImageNoteDiffResponse.data.createImageDiffNote,
      getDesignQuery,
      mockDesignVariables,
    );
    expect(findDesignReplyForm().exists()).toBe(false);
  });

  it('closes the form and clears the comment on canceling form', async () => {
    createComponent(
      { loading: false },
      {
        data: {
          design,
          annotationCoordinates,
        },
      },
    );

    findDesignReplyForm().vm.$emit('cancel-form');

    await nextTick();
    expect(findDesignReplyForm().exists()).toBe(false);
  });

  describe('with error', () => {
    beforeEach(() => {
      createComponent(
        { loading: false },
        {
          data: {
            design: mockDesignNoDiscussions,
            errorMessage: 'woops',
          },
        },
      );
    });

    it('GlAlert is rendered in correct position with correct content', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('onDesignQueryResult', () => {
    describe('with no designs', () => {
      it('redirects to /designs', async () => {
        createComponent({ loading: true });
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
        createComponent({ loading: true });
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
    it('calls updateActiveDiscussion mutation', () => {
      createComponent(
        { loading: false },
        {
          data: {
            design,
          },
          intialRouteOptions: { hash: '#note_123' },
        },
      );

      expect(mutate).toHaveBeenCalledTimes(1);
      expect(mutate).toHaveBeenCalledWith({
        mutation: updateActiveDiscussion,
        variables: { id: 'gid://gitlab/DiffNote/123', source: 'url' },
      });
    });
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    describe('on mount', () => {
      it('tracks design view in snowplow', () => {
        createComponent({ loading: true });

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
        createComponent({ loading: true });

        expect(Api.trackRedisHllUserEvent).toHaveBeenCalledTimes(1);
        expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(
          DESIGN_SERVICE_PING_EVENT_TYPES.DESIGN_ACTION,
        );
      });
    });
  });
});
