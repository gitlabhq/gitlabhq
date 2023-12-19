import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as urlUtility from '~/lib/utils/url_utility';
import SidebarService from '~/sidebar/services/sidebar_service';
import SidebarMediator from '~/sidebar/sidebar_mediator';
import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';

jest.mock('~/alert');
jest.mock('~/vue_shared/plugins/global_toast');

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
  });

  it('assigns yourself', () => {
    mediator.assignYourself();

    expect(mediator.store.currentUser).toEqual(mediatorMockData.currentUser);
    expect(mediator.store.assignees[0]).toEqual(mediatorMockData.currentUser);
  });

  it('saves assignees', () => {
    mock.onPut(mediatorMockData.endpoint).reply(HTTP_STATUS_OK, {});

    return mediator.saveAssignees('issue[assignee_ids]').then((resp) => {
      expect(resp.status).toEqual(HTTP_STATUS_OK);
    });
  });

  it('assigns yourself as a reviewer', () => {
    mediator.addSelfReview();

    expect(mediator.store.currentUser).toEqual(mediatorMockData.currentUser);
    expect(mediator.store.reviewers[0]).toEqual(mediatorMockData.currentUser);
  });

  describe('saves reviewers', () => {
    const mockUpdateResponseData = {
      reviewers: [1, 2],
      assignees: [3, 4],
    };
    const field = 'merge_request[reviewers_ids]';
    const reviewers = [
      { id: 1, suggested: true },
      { id: 2, suggested: false },
    ];

    let serviceSpy;

    beforeEach(() => {
      mediator.store.reviewers = reviewers;
      serviceSpy = jest
        .spyOn(mediator.service, 'update')
        .mockReturnValue(Promise.resolve({ data: mockUpdateResponseData }));
    });

    it('sends correct data to service', () => {
      const data = {
        reviewer_ids: [1, 2],
        suggested_reviewer_ids: [1],
      };

      mediator.saveReviewers(field);

      expect(serviceSpy).toHaveBeenCalledWith(field, data);
    });

    it('saves reviewers', () => {
      return mediator.saveReviewers(field).then(() => {
        expect(mediator.store.assignees).toEqual(mockUpdateResponseData.assignees);
        expect(mediator.store.reviewers).toEqual(mockUpdateResponseData.reviewers);
      });
    });
  });

  it('fetches the data', async () => {
    const mockData = Mock.responseMap.GET[mediatorMockData.endpoint];
    mock.onGet(mediatorMockData.endpoint).reply(HTTP_STATUS_OK, mockData);
    const spy = jest.spyOn(mediator, 'processFetchedData').mockReturnValue(Promise.resolve());
    await mediator.fetch();

    expect(spy).toHaveBeenCalledWith(mockData);
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
  });

  it('fetches autocomplete projects', () => {
    const searchTerm = 'foo';
    mock.onGet(mediatorMockData.projectsAutocompleteEndpoint).reply(HTTP_STATUS_OK, {});
    const getterSpy = jest
      .spyOn(mediator.service, 'getProjectsAutocomplete')
      .mockReturnValue(Promise.resolve({ data: {} }));
    const setterSpy = jest
      .spyOn(mediator.store, 'setAutocompleteProjects')
      .mockReturnValue(Promise.resolve());

    return mediator.fetchAutocompleteProjects(searchTerm).then(() => {
      expect(getterSpy).toHaveBeenCalledWith(searchTerm);
      expect(setterSpy).toHaveBeenCalled();
    });
  });

  it('moves issue', () => {
    const mockData = Mock.responseMap.POST[mediatorMockData.moveIssueEndpoint];
    const moveToProjectId = 7;
    mock.onPost(mediatorMockData.moveIssueEndpoint).reply(HTTP_STATUS_OK, mockData);
    mediator.store.setMoveToProjectId(moveToProjectId);
    const moveIssueSpy = jest
      .spyOn(mediator.service, 'moveIssue')
      .mockReturnValue(Promise.resolve({ data: { web_url: mockData.web_url } }));
    const urlSpy = jest.spyOn(urlUtility, 'visitUrl').mockReturnValue({});

    return mediator.moveIssue().then(() => {
      expect(moveIssueSpy).toHaveBeenCalledWith(moveToProjectId);
      expect(urlSpy).toHaveBeenCalledWith(mockData.web_url);
    });
  });
});
