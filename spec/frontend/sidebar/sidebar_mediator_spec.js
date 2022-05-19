import MockAdapter from 'axios-mock-adapter';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import * as urlUtility from '~/lib/utils/url_utility';
import SidebarService, { gqClient } from '~/sidebar/services/sidebar_service';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import toast from '~/vue_shared/plugins/global_toast';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import Mock from './mock_data';

jest.mock('~/flash');
jest.mock('~/vue_shared/plugins/global_toast');
jest.mock('~/commons/nav/user_merge_requests');

describe('Sidebar mediator', () => {
  const { mediator: mediatorMockData } = Mock;
  let mock;
  let mediator;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mediator = new SidebarMediator(mediatorMockData);
  });

  afterEach(() => {
    SidebarService.singleton = null;
    SidebarStore.singleton = null;
    SidebarMediator.singleton = null;
    mock.restore();
  });

  it('assigns yourself ', () => {
    mediator.assignYourself();

    expect(mediator.store.currentUser).toEqual(mediatorMockData.currentUser);
    expect(mediator.store.assignees[0]).toEqual(mediatorMockData.currentUser);
  });

  it('saves assignees', () => {
    mock.onPut(mediatorMockData.endpoint).reply(200, {});

    return mediator.saveAssignees('issue[assignee_ids]').then((resp) => {
      expect(resp.status).toEqual(200);
    });
  });

  it('fetches the data', () => {
    const mockData = Mock.responseMap.GET[mediatorMockData.endpoint];
    mock.onGet(mediatorMockData.endpoint).reply(200, mockData);

    const mockGraphQlData = Mock.graphQlResponseData;
    const graphQlSpy = jest.spyOn(gqClient, 'query').mockReturnValue({
      data: mockGraphQlData,
    });
    const spy = jest.spyOn(mediator, 'processFetchedData').mockReturnValue(Promise.resolve());

    return mediator.fetch().then(() => {
      expect(spy).toHaveBeenCalledWith(mockData, mockGraphQlData);

      spy.mockRestore();
      graphQlSpy.mockRestore();
    });
  });

  it('processes fetched data', () => {
    const mockData = Mock.responseMap.GET[mediatorMockData.endpoint];
    mediator.processFetchedData(mockData);

    expect(mediator.store.assignees).toEqual(mockData.assignees);
    expect(mediator.store.humanTimeEstimate).toEqual(mockData.human_time_estimate);
    expect(mediator.store.humanTotalTimeSpent).toEqual(mockData.human_total_time_spent);
    expect(mediator.store.timeEstimate).toEqual(mockData.time_estimate);
    expect(mediator.store.totalTimeSpent).toEqual(mockData.total_time_spent);
  });

  it('sets moveToProjectId', () => {
    const projectId = 7;
    const spy = jest.spyOn(mediator.store, 'setMoveToProjectId').mockReturnValue(Promise.resolve());

    mediator.setMoveToProjectId(projectId);

    expect(spy).toHaveBeenCalledWith(projectId);

    spy.mockRestore();
  });

  it('fetches autocomplete projects', () => {
    const searchTerm = 'foo';
    mock.onGet(mediatorMockData.projectsAutocompleteEndpoint).reply(200, {});
    const getterSpy = jest
      .spyOn(mediator.service, 'getProjectsAutocomplete')
      .mockReturnValue(Promise.resolve({ data: {} }));
    const setterSpy = jest
      .spyOn(mediator.store, 'setAutocompleteProjects')
      .mockReturnValue(Promise.resolve());

    return mediator.fetchAutocompleteProjects(searchTerm).then(() => {
      expect(getterSpy).toHaveBeenCalledWith(searchTerm);
      expect(setterSpy).toHaveBeenCalled();

      getterSpy.mockRestore();
      setterSpy.mockRestore();
    });
  });

  it('moves issue', () => {
    const mockData = Mock.responseMap.POST[mediatorMockData.moveIssueEndpoint];
    const moveToProjectId = 7;
    mock.onPost(mediatorMockData.moveIssueEndpoint).reply(200, mockData);
    mediator.store.setMoveToProjectId(moveToProjectId);
    const moveIssueSpy = jest
      .spyOn(mediator.service, 'moveIssue')
      .mockReturnValue(Promise.resolve({ data: { web_url: mockData.web_url } }));
    const urlSpy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

    return mediator.moveIssue().then(() => {
      expect(moveIssueSpy).toHaveBeenCalledWith(moveToProjectId);
      expect(urlSpy).toHaveBeenCalledWith(mockData.web_url);

      moveIssueSpy.mockRestore();
      urlSpy.mockRestore();
    });
  });

  describe('toggleAttentionRequested', () => {
    let requestAttentionMock;
    let removeAttentionRequestMock;

    beforeEach(() => {
      requestAttentionMock = jest.spyOn(mediator.service, 'requestAttention').mockResolvedValue();
      removeAttentionRequestMock = jest
        .spyOn(mediator.service, 'removeAttentionRequest')
        .mockResolvedValue();
    });

    it.each`
      attentionIsCurrentlyRequested | serviceMethod
      ${true}                       | ${'remove'}
      ${false}                      | ${'add'}
    `(
      "calls the $serviceMethod service method when the user's attention request is set to $attentionIsCurrentlyRequested",
      async ({ serviceMethod }) => {
        const methods = {
          add: requestAttentionMock,
          remove: removeAttentionRequestMock,
        };
        mediator.store.reviewers = [{ id: 1, attention_requested: false, username: 'root' }];

        await mediator.toggleAttentionRequested('reviewer', {
          user: { id: 1, username: 'root' },
          callback: jest.fn(),
          direction: serviceMethod,
        });

        expect(methods[serviceMethod]).toHaveBeenCalledWith(1);
        expect(refreshUserMergeRequestCounts).toHaveBeenCalled();
      },
    );

    it.each`
      type          | method
      ${'reviewer'} | ${'findReviewer'}
    `('finds $type', ({ type, method }) => {
      const methodSpy = jest.spyOn(mediator.store, method);

      mediator.toggleAttentionRequested(type, { user: { id: 1 }, callback: jest.fn() });

      expect(methodSpy).toHaveBeenCalledWith({ id: 1 });
    });

    it.each`
      attentionRequested | toastMessage
      ${true}            | ${'Removed attention request from @root'}
      ${false}           | ${'Requested attention from @root'}
    `(
      'it creates toast $toastMessage when attention_requested is $attentionRequested',
      async ({ attentionRequested, toastMessage }) => {
        mediator.store.reviewers = [
          { id: 1, attention_requested: attentionRequested, username: 'root' },
        ];

        await mediator.toggleAttentionRequested('reviewer', {
          user: { id: 1, username: 'root' },
          callback: jest.fn(),
        });

        expect(toast).toHaveBeenCalledWith(toastMessage);
      },
    );

    describe('errors', () => {
      beforeEach(() => {
        jest
          .spyOn(mediator.service, 'removeAttentionRequest')
          .mockRejectedValueOnce(new Error('Something went wrong'));
      });

      it('shows an error message', async () => {
        await mediator.toggleAttentionRequested('reviewer', {
          user: { id: 1, username: 'root' },
          callback: jest.fn(),
          direction: 'remove',
        });

        expect(createFlash).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'Updating the attention request for root failed.',
          }),
        );
      });
    });
  });
});
