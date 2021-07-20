import { GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { ApolloMutation } from 'vue-apollo';
import VueRouter from 'vue-router';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import Api from '~/api';
import DesignPresentation from '~/design_management/components/design_presentation.vue';
import DesignSidebar from '~/design_management/components/design_sidebar.vue';
import { DESIGN_DETAIL_LAYOUT_CLASSLIST } from '~/design_management/constants';
import createImageDiffNoteMutation from '~/design_management/graphql/mutations/create_image_diff_note.mutation.graphql';
import updateActiveDiscussion from '~/design_management/graphql/mutations/update_active_discussion.mutation.graphql';
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
import createFlash from '~/flash';
import mockAllVersions from '../../mock_data/all_versions';
import design from '../../mock_data/design';
import mockResponseWithDesigns from '../../mock_data/designs';
import mockResponseNoDesigns from '../../mock_data/no_designs';

jest.mock('~/flash');
jest.mock('~/api.js');

const focusInput = jest.fn();
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
const newComment = 'new comment';
const annotationCoordinates = {
  x: 10,
  y: 10,
  width: 100,
  height: 100,
};
const createDiscussionMutationVariables = {
  mutation: createImageDiffNoteMutation,
  update: expect.anything(),
  variables: {
    input: {
      body: newComment,
      noteableId: design.id,
      position: {
        headSha: 'headSha',
        baseSha: 'baseSha',
        startSha: 'startSha',
        paths: {
          newPath: 'full-design-path',
        },
        ...annotationCoordinates,
      },
    },
  },
};

const localVue = createLocalVue();
localVue.use(VueRouter);

describe('Design management design index page', () => {
  let wrapper;
  let router;

  const findDiscussionForm = () => wrapper.find(DesignReplyForm);
  const findSidebar = () => wrapper.find(DesignSidebar);
  const findDesignPresentation = () => wrapper.find(DesignPresentation);

  function createComponent(
    { loading = false } = {},
    { data = {}, intialRouteOptions = {}, provide = {} } = {},
  ) {
    const $apollo = {
      queries: {
        design: {
          loading,
        },
      },
      mutate,
    };

    router = createRouter();

    router.push({ name: DESIGN_ROUTE_NAME, params: { id: design.id }, ...intialRouteOptions });

    wrapper = shallowMount(DesignIndex, {
      propsData: { id: '1' },
      mocks: { $apollo },
      stubs: {
        ApolloMutation,
        DesignSidebar,
        DesignReplyForm,
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
      localVue,
      router,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when navigating to component', () => {
    it('applies fullscreen layout class', () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent({ loading: true });

      expect(mockPageLayoutElement.classList.add).toHaveBeenCalledTimes(1);
      expect(mockPageLayoutElement.classList.add).toHaveBeenCalledWith(
        ...DESIGN_DETAIL_LAYOUT_CLASSLIST,
      );
    });
  });

  describe('when navigating within the component', () => {
    it('`scale` prop of DesignPresentation component is 1', async () => {
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageLayoutElement);
      createComponent({ loading: false }, { data: { design, scale: 2 } });

      await wrapper.vm.$nextTick();
      expect(findDesignPresentation().props('scale')).toBe(2);

      DesignIndex.beforeRouteUpdate.call(wrapper.vm, {}, {}, jest.fn());
      await wrapper.vm.$nextTick();

      expect(findDesignPresentation().props('scale')).toBe(1);
    });
  });

  describe('when navigating away from component', () => {
    it('removes fullscreen layout class', async () => {
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

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders design index', () => {
    createComponent({ loading: false }, { data: { design } });

    expect(wrapper.element).toMatchSnapshot();
    expect(wrapper.find(GlAlert).exists()).toBe(false);
  });

  it('passes correct props to sidebar component', () => {
    createComponent({ loading: false }, { data: { design } });

    expect(findSidebar().props()).toEqual({
      design,
      markdownPreviewPath: '/project-path/preview_markdown?target_type=Issue',
      resolvedDiscussionsExpanded: false,
    });
  });

  it('opens a new discussion form', () => {
    createComponent(
      { loading: false },
      {
        data: {
          design,
        },
      },
    );

    findDesignPresentation().vm.$emit('openCommentForm', { x: 0, y: 0 });

    return wrapper.vm.$nextTick().then(() => {
      expect(findDiscussionForm().exists()).toBe(true);
    });
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

  it('sends a mutation on submitting form and closes form', () => {
    createComponent(
      { loading: false },
      {
        data: {
          design,
          annotationCoordinates,
          comment: newComment,
        },
      },
    );

    findDiscussionForm().vm.$emit('submit-form');
    expect(mutate).toHaveBeenCalledWith(createDiscussionMutationVariables);

    return wrapper.vm
      .$nextTick()
      .then(() => {
        return mutate({ variables: createDiscussionMutationVariables });
      })
      .then(() => {
        expect(findDiscussionForm().exists()).toBe(false);
      });
  });

  it('closes the form and clears the comment on canceling form', () => {
    createComponent(
      { loading: false },
      {
        data: {
          design,
          annotationCoordinates,
          comment: newComment,
        },
      },
    );

    findDiscussionForm().vm.$emit('cancel-form');

    expect(wrapper.vm.comment).toBe('');

    return wrapper.vm.$nextTick().then(() => {
      expect(findDiscussionForm().exists()).toBe(false);
    });
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
      it('redirects to /designs', () => {
        createComponent({ loading: true });
        router.push = jest.fn();

        wrapper.vm.onDesignQueryResult({ data: mockResponseNoDesigns, loading: false });
        return wrapper.vm.$nextTick().then(() => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith({ message: DESIGN_NOT_FOUND_ERROR });
          expect(router.push).toHaveBeenCalledTimes(1);
          expect(router.push).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
        });
      });
    });

    describe('when no design exists for given version', () => {
      it('redirects to /designs', () => {
        createComponent({ loading: true });
        wrapper.setData({
          allVersions: mockAllVersions,
        });

        // attempt to query for a version of the design that doesn't exist
        router.push({ query: { version: '999' } });
        router.push = jest.fn();

        wrapper.vm.onDesignQueryResult({ data: mockResponseWithDesigns, loading: false });
        return wrapper.vm.$nextTick().then(() => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith({ message: DESIGN_VERSION_NOT_EXIST_ERROR });
          expect(router.push).toHaveBeenCalledTimes(1);
          expect(router.push).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
        });
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

      describe('with usage_data_design_action enabled', () => {
        it('tracks design view service ping', () => {
          createComponent(
            { loading: true },
            {
              provide: {
                glFeatures: { usageDataDesignAction: true },
              },
            },
          );
          expect(Api.trackRedisHllUserEvent).toHaveBeenCalledTimes(1);
          expect(Api.trackRedisHllUserEvent).toHaveBeenCalledWith(
            DESIGN_SERVICE_PING_EVENT_TYPES.DESIGN_ACTION,
          );
        });
      });

      describe('with usage_data_design_action disabled', () => {
        it("doesn't track design view service ping", () => {
          createComponent({ loading: true });
          expect(Api.trackRedisHllUserEvent).toHaveBeenCalledTimes(0);
        });
      });
    });
  });
});
