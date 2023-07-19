import GroupsService from '~/groups/service/groups_service';
import axios from '~/lib/utils/axios_utils';

import { mockEndpoint, mockParentGroupItem } from '../mock_data';

describe('GroupsService', () => {
  let service;

  beforeEach(() => {
    service = new GroupsService(mockEndpoint, 'created_asc');
  });

  describe('getGroups', () => {
    it('should return promise for `GET` request on provided endpoint', () => {
      jest.spyOn(axios, 'get').mockResolvedValue();
      const params = {
        page: 2,
        filter: 'git',
        sort: 'created_asc',
      };

      service.getGroups(55, 2, 'git', 'created_asc');

      expect(axios.get).toHaveBeenCalledWith(mockEndpoint, { params: { parent_id: 55 } });

      service.getGroups(null, 2, 'git', 'created_asc');

      expect(axios.get).toHaveBeenCalledWith(mockEndpoint, { params });
    });

    describe('when sort argument is undefined', () => {
      it('calls API with `initialSort` argument', () => {
        jest.spyOn(axios, 'get').mockResolvedValue();

        service.getGroups(undefined, 2, 'git', undefined);

        expect(axios.get).toHaveBeenCalledWith(mockEndpoint, {
          params: { sort: 'created_asc', filter: 'git', page: 2 },
        });
      });
    });
  });

  describe('leaveGroup', () => {
    it('should return promise for `DELETE` request on provided endpoint', () => {
      jest.spyOn(axios, 'delete').mockResolvedValue();

      service.leaveGroup(mockParentGroupItem.leavePath);

      expect(axios.delete).toHaveBeenCalledWith(mockParentGroupItem.leavePath);
    });
  });
});
