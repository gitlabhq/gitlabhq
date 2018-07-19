import axios from '~/lib/utils/axios_utils';

import SidebarService from 'ee/epics/sidebar/services/sidebar_service';

describe('Sidebar Service', () => {
  let service;

  beforeEach(() => {
    service = new SidebarService({
      endpoint: gl.TEST_HOST,
      subscriptionEndpoint: gl.TEST_HOST,
      todoPath: gl.TEST_HOST,
    });
  });

  describe('updateStartDate', () => {
    it('returns axios instance with PUT for `endpoint` with `start_date_is_fixed` and `start_date_fixed` as request body', () => {
      spyOn(axios, 'put').and.stub();
      const dateValue = '2018-06-21';
      service.updateStartDate({ dateValue, isFixed: true });
      expect(axios.put).toHaveBeenCalledWith(service.endpoint, {
        start_date_is_fixed: true,
        start_date_fixed: dateValue,
      });
    });
  });

  describe('updateEndDate', () => {
    it('returns axios instance with PUT for `endpoint` with `due_date_is_fixed` and `due_date_fixed` as request body', () => {
      spyOn(axios, 'put').and.stub();
      const dateValue = '2018-06-21';
      service.updateEndDate({ dateValue, isFixed: true });
      expect(axios.put).toHaveBeenCalledWith(service.endpoint, {
        due_date_is_fixed: true,
        due_date_fixed: dateValue,
      });
    });
  });

  describe('toggleSubscribed', () => {
    it('returns axios instance with POST for `subscriptionEndpoint`', () => {
      spyOn(axios, 'post').and.stub();
      service.toggleSubscribed();
      expect(axios.post).toHaveBeenCalled();
    });
  });

  describe('addTodo', () => {
    it('returns axios instance with POST for `todoPath` with `issuable_id` and `issuable_type` as request body', () => {
      spyOn(axios, 'post').and.stub();
      const epicId = 1;
      service.addTodo(epicId);
      expect(axios.post).toHaveBeenCalledWith(service.todoPath, {
        issuable_id: epicId,
        issuable_type: 'epic',
      });
    });
  });

  describe('deleteTodo', () => {
    it('returns axios instance with DELETE for provided `todoDeletePath` param', () => {
      spyOn(axios, 'delete').and.stub();
      service.deleteTodo('/foo/bar');
      expect(axios.delete).toHaveBeenCalledWith('/foo/bar');
    });
  });
});
