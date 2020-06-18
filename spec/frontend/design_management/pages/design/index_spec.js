import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueRouter from 'vue-router';
import { GlAlert } from '@gitlab/ui';
import { ApolloMutation } from 'vue-apollo';
import createFlash from '~/flash';
import DesignIndex from '~/design_management/pages/design/index.vue';
import DesignSidebar from '~/design_management/components/design_sidebar.vue';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import createImageDiffNoteMutation from '~/design_management/graphql/mutations/createImageDiffNote.mutation.graphql';
import design from '../../mock_data/design';
import mockResponseWithDesigns from '../../mock_data/designs';
import mockResponseNoDesigns from '../../mock_data/no_designs';
import mockAllVersions from '../../mock_data/all_versions';
import {
  DESIGN_NOT_FOUND_ERROR,
  DESIGN_VERSION_NOT_EXIST_ERROR,
} from '~/design_management/utils/error_messages';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';
import createRouter from '~/design_management/router';
import * as utils from '~/design_management/utils/design_management_utils';
import { DESIGN_DETAIL_LAYOUT_CLASSLIST } from '~/design_management/constants';

jest.mock('~/flash');
jest.mock('mousetrap', () => ({
  bind: jest.fn(),
  unbind: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(VueRouter);

describe('Design management design index page', () => {
  let wrapper;
  let router;

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

  const mutate = jest.fn().mockResolvedValue();

  const findDiscussionForm = () => wrapper.find(DesignReplyForm);
  const findSidebar = () => wrapper.find(DesignSidebar);

  function createComponent(loading = false, data = {}) {
    const $apollo = {
      queries: {
        design: {
          loading,
        },
      },
      mutate,
    };

    router = createRouter();

    wrapper = shallowMount(DesignIndex, {
      propsData: { id: '1' },
      mocks: { $apollo },
      stubs: {
        ApolloMutation,
        DesignSidebar,
      },
      data() {
        return {
          issueIid: '1',
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

  describe('when navigating', () => {
    it('applies fullscreen layout', () => {
      const mockEl = {
        classList: {
          add: jest.fn(),
          remove: jest.fn(),
        },
      };
      jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockEl);
      createComponent(true);

      wrapper.vm.$router.push('/designs/test');
      expect(mockEl.classList.add).toHaveBeenCalledTimes(1);
      expect(mockEl.classList.add).toHaveBeenCalledWith(...DESIGN_DETAIL_LAYOUT_CLASSLIST);
    });
  });

  it('sets loading state', () => {
    createComponent(true);

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders design index', () => {
    createComponent(false, { design });

    expect(wrapper.element).toMatchSnapshot();
    expect(wrapper.find(GlAlert).exists()).toBe(false);
  });

  it('passes correct props to sidebar component', () => {
    createComponent(false, { design });

    expect(findSidebar().props()).toEqual({
      design,
      markdownPreviewPath: '//preview_markdown?target_type=Issue',
      resolvedDiscussionsExpanded: false,
    });
  });

  it('opens a new discussion form', () => {
    createComponent(false, {
      design: {
        ...design,
        discussions: {
          nodes: [],
        },
      },
    });

    wrapper.vm.openCommentForm({ x: 0, y: 0 });

    return wrapper.vm.$nextTick().then(() => {
      expect(findDiscussionForm().exists()).toBe(true);
    });
  });

  it('sends a mutation on submitting form and closes form', () => {
    createComponent(false, {
      design: {
        ...design,
        discussions: {
          nodes: [],
        },
      },
      annotationCoordinates,
      comment: newComment,
    });

    findDiscussionForm().vm.$emit('submitForm');
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
    createComponent(false, {
      design: {
        ...design,
        discussions: {
          nodes: [],
        },
      },
      annotationCoordinates,
      comment: newComment,
    });

    findDiscussionForm().vm.$emit('cancelForm');

    expect(wrapper.vm.comment).toBe('');

    return wrapper.vm.$nextTick().then(() => {
      expect(findDiscussionForm().exists()).toBe(false);
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      createComponent(false, {
        design: {
          ...design,
          discussions: {
            nodes: [],
          },
        },
        errorMessage: 'woops',
      });
    });

    it('GlAlert is rendered in correct position with correct content', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('onDesignQueryResult', () => {
    describe('with no designs', () => {
      it('redirects to /designs', () => {
        createComponent(true);
        router.push = jest.fn();

        wrapper.vm.onDesignQueryResult({ data: mockResponseNoDesigns, loading: false });
        return wrapper.vm.$nextTick().then(() => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith(DESIGN_NOT_FOUND_ERROR);
          expect(router.push).toHaveBeenCalledTimes(1);
          expect(router.push).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
        });
      });
    });

    describe('when no design exists for given version', () => {
      it('redirects to /designs', () => {
        createComponent(true);
        wrapper.setData({
          allVersions: mockAllVersions,
        });

        // attempt to query for a version of the design that doesn't exist
        router.push({ query: { version: '999' } });
        router.push = jest.fn();

        wrapper.vm.onDesignQueryResult({ data: mockResponseWithDesigns, loading: false });
        return wrapper.vm.$nextTick().then(() => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith(DESIGN_VERSION_NOT_EXIST_ERROR);
          expect(router.push).toHaveBeenCalledTimes(1);
          expect(router.push).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
        });
      });
    });
  });
});
