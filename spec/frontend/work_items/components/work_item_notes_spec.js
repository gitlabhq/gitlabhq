import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import WorkItemNotes from '~/work_items/components/work_item_notes.vue';
import workItemNotesQuery from '~/work_items/graphql/work_item_notes.query.graphql';
import workItemNotesByIidQuery from '~/work_items/graphql/work_item_notes_by_iid.query.graphql';
import { WIDGET_TYPE_NOTES } from '~/work_items/constants';
import {
  mockWorkItemNotesResponse,
  workItemQueryResponse,
  mockWorkItemNotesByIidResponse,
} from '../mock_data';

const mockWorkItemId = workItemQueryResponse.data.workItem.id;
const mockNotesWidgetResponse = mockWorkItemNotesResponse.data.workItem.widgets.find(
  (widget) => widget.type === WIDGET_TYPE_NOTES,
);

const mockNotesByIidWidgetResponse = mockWorkItemNotesByIidResponse.data.workspace.workItems.nodes[0].widgets.find(
  (widget) => widget.type === WIDGET_TYPE_NOTES,
);

describe('WorkItemNotes component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const findAllSystemNotes = () => wrapper.findAllComponents(SystemNote);
  const findActivityLabel = () => wrapper.find('label');
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const workItemNotesQueryHandler = jest.fn().mockResolvedValue(mockWorkItemNotesResponse);
  const workItemNotesByIidQueryHandler = jest
    .fn()
    .mockResolvedValue(mockWorkItemNotesByIidResponse);

  const createComponent = ({ workItemId = mockWorkItemId, fetchByIid = false } = {}) => {
    wrapper = shallowMount(WorkItemNotes, {
      apolloProvider: createMockApollo([
        [workItemNotesQuery, workItemNotesQueryHandler],
        [workItemNotesByIidQuery, workItemNotesByIidQueryHandler],
      ]),
      propsData: {
        workItemId,
        queryVariables: {
          id: workItemId,
        },
        fullPath: 'test-path',
        fetchByIid,
      },
      provide: {
        glFeatures: {
          useIidInWorkItemsPath: fetchByIid,
        },
      },
    });
  };

  beforeEach(async () => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders activity label', () => {
    expect(findActivityLabel().exists()).toBe(true);
  });

  describe('when notes are loading', () => {
    it('renders skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('does not render system notes', () => {
      expect(findAllSystemNotes().exists()).toBe(false);
    });
  });

  describe('when notes have been loaded', () => {
    it('does not render skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('renders system notes to the length of the response', async () => {
      await waitForPromises();
      expect(findAllSystemNotes()).toHaveLength(mockNotesWidgetResponse.discussions.nodes.length);
    });
  });

  describe('when the notes are fetched by `iid`', () => {
    beforeEach(async () => {
      createComponent({ workItemId: mockWorkItemId, fetchByIid: true });
      await waitForPromises();
    });

    it('shows the notes list', () => {
      expect(findAllSystemNotes()).toHaveLength(
        mockNotesByIidWidgetResponse.discussions.nodes.length,
      );
    });
  });
});
