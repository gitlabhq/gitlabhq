import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import SkeletonLoadingContainer from '~/vue_shared/components/notes/skeleton_note.vue';
import abuseReportNotesQuery from '~/admin/abuse_report/graphql/notes/abuse_report_notes.query.graphql';
import AbuseReportNotes from '~/admin/abuse_report/components/abuse_report_notes.vue';
import AbuseReportDiscussion from '~/admin/abuse_report/components/notes/abuse_report_discussion.vue';
import AbuseReportAddNote from '~/admin/abuse_report/components/notes/abuse_report_add_note.vue';

import { mockAbuseReport, mockNotesByIdResponse } from '../mock_data';

jest.mock('~/alert');

describe('Abuse Report Notes', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mockAbuseReportId = mockAbuseReport.report.globalId;

  const notesQueryHandler = jest.fn().mockResolvedValue(mockNotesByIdResponse);

  const findSkeletonLoaders = () => wrapper.findAllComponents(SkeletonLoadingContainer);
  const findAbuseReportDiscussions = () => wrapper.findAllComponents(AbuseReportDiscussion);
  const findAbuseReportAddNote = () => wrapper.findComponent(AbuseReportAddNote);

  const createComponent = ({
    queryHandler = notesQueryHandler,
    abuseReportId = mockAbuseReportId,
  } = {}) => {
    wrapper = shallowMount(AbuseReportNotes, {
      apolloProvider: createMockApollo([[abuseReportNotesQuery, queryHandler]]),
      propsData: {
        abuseReportId,
      },
    });
  };

  describe('when notes are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should show the skeleton loaders', () => {
      expect(findSkeletonLoaders()).toHaveLength(5);
    });
  });

  describe('when notes have been loaded', () => {
    beforeEach(() => {
      createComponent();
      return waitForPromises();
    });

    it('should not render skeleton loader', () => {
      expect(findSkeletonLoaders()).toHaveLength(0);
    });

    it('should call the abuse report notes query', () => {
      expect(notesQueryHandler).toHaveBeenCalledWith({
        id: mockAbuseReportId,
      });
    });

    it('should show notes to the length of the response', () => {
      expect(findAbuseReportDiscussions()).toHaveLength(2);

      const discussions = mockNotesByIdResponse.data.abuseReport.discussions.nodes;

      expect(findAbuseReportDiscussions().at(0).props()).toMatchObject({
        abuseReportId: mockAbuseReportId,
        discussion: discussions[0].notes.nodes,
      });

      expect(findAbuseReportDiscussions().at(1).props()).toMatchObject({
        abuseReportId: mockAbuseReportId,
        discussion: discussions[1].notes.nodes,
      });
    });

    it('should show the comment form', () => {
      expect(findAbuseReportAddNote().exists()).toBe(true);

      expect(findAbuseReportAddNote().props()).toMatchObject({
        abuseReportId: mockAbuseReportId,
        discussionId: '',
        isNewDiscussion: true,
      });
    });
  });

  describe('When there is an error fetching the notes', () => {
    beforeEach(() => {
      createComponent({
        queryHandler: jest.fn().mockRejectedValue(new Error()),
      });

      return waitForPromises();
    });

    it('should show an error when query fails', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while fetching comments, please try again.',
      });
    });
  });
});
