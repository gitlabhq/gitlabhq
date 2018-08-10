import axios from '~/lib/utils/axios_utils';

import RoadmapService from 'ee/roadmap/service/roadmap_service';
import { epicsPath } from '../mock_data';

describe('RoadmapService', () => {
  let service;

  beforeEach(() => {
    service = new RoadmapService(epicsPath);
  });

  describe('getEpics', () => {
    it('returns axios instance for Epics path', () => {
      spyOn(axios, 'get').and.stub();
      service.getEpics();
      expect(axios.get).toHaveBeenCalledWith(service.epicsPath);
    });
  });
});
