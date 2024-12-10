import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiNotesApp from '~/pages/shared/wikis/wiki_notes/components/wiki_notes_app.vue';
import WikiCommentForm from '~/pages/shared/wikis/wiki_notes/components/wiki_comment_form.vue';
import PlaceholderNote from '~/pages/shared/wikis/wiki_notes/components/placeholder_note.vue';
import SkeletonNote from '~/vue_shared/components/notes/skeleton_note.vue';
import WikiDiscussion from '~/pages/shared/wikis/wiki_notes/components/wiki_discussion.vue';
import WikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import { note, noteableId } from '../mock_data';

describe('WikiNotesApp', () => {
  let wrapper;

  const $apollo = {
    queries: {
      wikiPage: {
        loading: false,
        refetch: jest.fn().mockResolvedValue({}),
      },
    },
  };

  const createWrapper = ({ provideData = { containerType: 'project' } } = {}) =>
    shallowMountExtended(WikiNotesApp, {
      provide: {
        pageInfo: {
          slug: 'home',
        },
        containerId: noteableId,
        noteCount: 5,
        ...provideData,
      },
      mocks: {
        $apollo,
      },
    });

  beforeEach(() => {
    wrapper = createWrapper();
  });

  it('should render skeleton notes before content loads', () => {
    wrapper = createWrapper();
    const skeletonNotes = wrapper.findAllComponents(SkeletonNote);

    expect(skeletonNotes.length).toBe(5);
  });

  it('should render Comment Form correctly', () => {
    const commentForm = wrapper.findComponent(WikiCommentForm);

    expect(commentForm.props()).toMatchObject({
      noteableId: '',
      noteId: noteableId,
    });
  });

  it('should not render placeholder note by default', () => {
    const placeholderNote = wrapper.findComponent(PlaceholderNote);
    expect(placeholderNote.exists()).toBe(false);
  });

  it('should render placeholder note correctly when set', async () => {
    wrapper.vm.setPlaceHolderNote({ body: 'a placeholder' });
    await nextTick();

    const placeholderNote = wrapper.findComponent(PlaceholderNote);

    expect(placeholderNote.props('note')).toMatchObject({ body: 'a placeholder' });
  });

  describe('when there is an error while fetching discussions', () => {
    beforeEach(() => {
      wrapper.vm.$options.apollo.wikiPage.error.call(wrapper.vm);
    });

    afterEach(() => {
      jest.resetAllMocks();
    });

    it('should render error message correctly', async () => {
      const errorAlert = wrapper.findComponent(GlAlert);
      expect(await errorAlert.text()).toBe(
        'Something went wrong while fetching comments. Please refresh the page.',
      );
    });

    it('should render retry text correctly', async () => {
      const errorAlert = wrapper.findComponent(GlAlert);
      expect(await errorAlert.props('primaryButtonText')).toBe('Retry');
    });

    it('should not render any discussions', () => {
      const wikiDiscussions = wrapper.findAllComponents(WikiDiscussion);
      expect(wikiDiscussions.length).toBe(0);
    });

    it('should not render any skeleton notes', () => {
      const skeletonNotes = wrapper.findAllComponents(SkeletonNote);
      expect(skeletonNotes.length).toBe(0);
    });

    it('should attempt to fetch Discussions when retry button is clicked', async () => {
      const errorAlert = wrapper.findComponent(GlAlert);

      await errorAlert.vm.$emit('primaryAction');
      expect(wrapper.vm.$apollo.queries.wikiPage.refetch).toHaveBeenCalled();
    });
  });

  describe('when there are no errors while fetching discussions', () => {
    beforeEach(() => {
      const mockData = {
        wikiPage: {
          id: 'gid://gitlab/WikiPage/1',
          discussions: {
            nodes: [
              { id: 1, notes: { nodes: [{ body: 'Discussion 1' }] } },
              { id: 2, notes: { nodes: [{ body: 'Discussion 2' }] } },
            ],
          },
        },
      };

      wrapper.vm.$options.apollo.wikiPage.result.call(wrapper.vm, { data: mockData });
    });

    afterEach(() => {
      jest.resetAllMocks();
    });

    it('should render discussions correctly', () => {
      const wikiDiscussions = wrapper.findAllComponents(WikiDiscussion);

      expect(wikiDiscussions.length).toBe(2);
      expect(wikiDiscussions.at(0).props()).toMatchObject({
        discussion: [{ body: 'Discussion 1' }],
        noteableId: 'gid://gitlab/WikiPage/1',
      });
      expect(wikiDiscussions.at(1).props()).toMatchObject({
        discussion: [{ body: 'Discussion 2' }],
        noteableId: 'gid://gitlab/WikiPage/1',
      });
    });

    it('should not render error alert', () => {
      const errorAlert = wrapper.findComponent(GlAlert);
      expect(errorAlert.exists()).toBe(false);
    });
  });

  describe('when fetching discussions', () => {
    const setUpAndReturnVariables = (containerType) => {
      wrapper = createWrapper({ provideData: { containerType } });

      const variablesSpy = jest.spyOn(WikiNotesApp.apollo.wikiPage, 'variables');
      WikiNotesApp.apollo.wikiPage.variables.call(wrapper.vm);

      expect(wrapper.vm.$options.apollo.wikiPage.query).toBe(WikiPageQuery);
      return variablesSpy.mock.results[0].value;
    };

    afterEach(() => {
      jest.resetAllMocks();
    });

    it('should set variable data when containerType is group', () => {
      const variables = setUpAndReturnVariables('group');
      expect(variables).toMatchObject({ slug: 'home', namespaceId: 'gid://gitlab/Group/7' });
    });

    it('should set variable data when containerType is project', () => {
      const variables = setUpAndReturnVariables('project');

      expect(variables).toMatchObject({ slug: 'home', projectId: 'gid://gitlab/Project/7' });
    });
  });

  describe('wiki comment form', () => {
    it('should setPlaceHolder correctly when "creating-note:start" is called', async () => {
      const commentForm = wrapper.findComponent(WikiCommentForm);

      commentForm.vm.$emit('creating-note:start', { body: 'example placeholder' });
      await nextTick();

      const placeholderNote = wrapper.findComponent(PlaceholderNote);
      expect(placeholderNote.props('note')).toMatchObject({ body: 'example placeholder' });
    });

    it('should removePlaceholder when "creating-note:done" is called', async () => {
      wrapper.vm.setPlaceHolderNote({ body: 'example placeholder' });
      const commentForm = wrapper.findComponent(WikiCommentForm);
      commentForm.vm.$emit('creating-note:done');
      await nextTick();

      expect(wrapper.vm.placeholderNote).toMatchObject({});
    });

    it('shouldupdateDiscussions when "creating-note:success" is called', async () => {
      const mockData = {
        wikiPage: {
          id: 'gid://gitlab/WikiPage/1',
          discussions: {
            nodes: [{ id: 1, notes: { nodes: [{ body: 'Discussion 1' }] } }],
          },
        },
      };
      wrapper.vm.$options.apollo.wikiPage.result.call(wrapper.vm, { data: mockData });
      await nextTick();

      const newDiscussion = {
        id: '2',
        notes: {
          nodes: [
            {
              ...note,
              id: 2,
              body: 'New Comment',
            },
          ],
        },
      };
      const commentForm = wrapper.findComponent(WikiCommentForm);
      commentForm.vm.$emit('creating-note:success', newDiscussion);
      await nextTick();

      const discussions = wrapper.findAllComponents(WikiDiscussion);
      expect(discussions.length).toBe(2);
      expect(discussions.at(1).props('discussion')).toMatchObject(newDiscussion.notes.nodes);
    });
  });
});
