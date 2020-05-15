import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import { ApolloMutation } from 'vue-apollo';
import createFlash from '~/flash';
import DesignIndex from '~/design_management/pages/design/index.vue';
import DesignDiscussion from '~/design_management/components/design_notes/design_discussion.vue';
import DesignReplyForm from '~/design_management/components/design_notes/design_reply_form.vue';
import Participants from '~/sidebar/components/participants/participants.vue';
import createImageDiffNoteMutation from '~/design_management/graphql/mutations/createImageDiffNote.mutation.graphql';
import updateActiveDiscussionMutation from '~/design_management/graphql/mutations/update_active_discussion.mutation.graphql';
import design from '../../mock_data/design';
import mockResponseWithDesigns from '../../mock_data/designs';
import mockResponseNoDesigns from '../../mock_data/no_designs';
import mockAllVersions from '../../mock_data/all_versions';
import {
  DESIGN_NOT_FOUND_ERROR,
  DESIGN_VERSION_NOT_EXIST_ERROR,
} from '~/design_management/utils/error_messages';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';

jest.mock('~/flash');
jest.mock('mousetrap', () => ({
  bind: jest.fn(),
  unbind: jest.fn(),
}));

describe('Design management design index page', () => {
  let wrapper;
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

  const updateActiveDiscussionMutationVariables = {
    mutation: updateActiveDiscussionMutation,
    variables: {
      id: design.discussions.nodes[0].notes.nodes[0].id,
      source: 'discussion',
    },
  };

  const mutate = jest.fn().mockResolvedValue();
  const routerPush = jest.fn();

  const findDiscussions = () => wrapper.findAll(DesignDiscussion);
  const findDiscussionForm = () => wrapper.find(DesignReplyForm);
  const findParticipants = () => wrapper.find(Participants);
  const findDiscussionsWrapper = () => wrapper.find('.image-notes');

  function createComponent(loading = false, data = {}, { routeQuery = {} } = {}) {
    const $apollo = {
      queries: {
        design: {
          loading,
        },
      },
      mutate,
    };

    const $router = {
      push: routerPush,
    };

    const $route = {
      query: routeQuery,
    };

    wrapper = shallowMount(DesignIndex, {
      propsData: { id: '1' },
      mocks: { $apollo, $router, $route },
      stubs: {
        ApolloMutation,
        DesignDiscussion,
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
    });
  }

  afterEach(() => {
    wrapper.destroy();
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

  it('renders participants', () => {
    createComponent(false, { design });

    expect(findParticipants().exists()).toBe(true);
  });

  it('passes the correct amount of participants to the Participants component', () => {
    createComponent(false, { design });

    expect(findParticipants().props('participants')).toHaveLength(1);
  });

  describe('when has no discussions', () => {
    beforeEach(() => {
      createComponent(false, {
        design: {
          ...design,
          discussions: {
            nodes: [],
          },
        },
      });
    });

    it('does not render discussions', () => {
      expect(findDiscussions().exists()).toBe(false);
    });

    it('renders a message about possibility to create a new discussion', () => {
      expect(wrapper.find('.new-discussion-disclaimer').exists()).toBe(true);
    });
  });

  describe('when has discussions', () => {
    beforeEach(() => {
      createComponent(false, { design });
    });

    it('renders correct amount of discussions', () => {
      expect(findDiscussions()).toHaveLength(1);
    });

    it('sends a mutation to set an active discussion when clicking on a discussion', () => {
      findDiscussions()
        .at(0)
        .trigger('click');

      expect(mutate).toHaveBeenCalledWith(updateActiveDiscussionMutationVariables);
    });

    it('sends a mutation to reset an active discussion when clicking outside of discussion', () => {
      findDiscussionsWrapper().trigger('click');

      expect(mutate).toHaveBeenCalledWith({
        ...updateActiveDiscussionMutationVariables,
        variables: { id: undefined, source: 'discussion' },
      });
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

        wrapper.vm.onDesignQueryResult({ data: mockResponseNoDesigns, loading: false });
        return wrapper.vm.$nextTick().then(() => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith(DESIGN_NOT_FOUND_ERROR);
          expect(routerPush).toHaveBeenCalledTimes(1);
          expect(routerPush).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
        });
      });
    });

    describe('when no design exists for given version', () => {
      it('redirects to /designs', () => {
        // attempt to query for a version of the design that doesn't exist
        createComponent(true, {}, { routeQuery: { version: '999' } });
        wrapper.setData({
          allVersions: mockAllVersions,
        });

        wrapper.vm.onDesignQueryResult({ data: mockResponseWithDesigns, loading: false });
        return wrapper.vm.$nextTick().then(() => {
          expect(createFlash).toHaveBeenCalledTimes(1);
          expect(createFlash).toHaveBeenCalledWith(DESIGN_VERSION_NOT_EXIST_ERROR);
          expect(routerPush).toHaveBeenCalledTimes(1);
          expect(routerPush).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
        });
      });
    });
  });
});
