import AxiosMockAdapter from 'axios-mock-adapter';
import ServiceDeskService from '~/projects/settings_service_desk/services/service_desk_service';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

describe('ServiceDeskService', () => {
  const endpoint = `/gitlab-org/gitlab-test/service_desk`;
  const dummyResponse = { message: 'Dummy response' };
  const errorMessage = 'Network Error';
  let axiosMock;
  let service;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    service = new ServiceDeskService(endpoint);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('toggleServiceDesk', () => {
    it('makes a request to set service desk', () => {
      axiosMock.onPut(endpoint).replyOnce(httpStatusCodes.OK, dummyResponse);

      return service.toggleServiceDesk(true).then(response => {
        expect(response.data).toEqual(dummyResponse);
      });
    });

    it('fails on error response', () => {
      axiosMock.onPut(endpoint).networkError();

      return service.toggleServiceDesk(true).catch(error => {
        expect(error.message).toBe(errorMessage);
      });
    });

    it('makes a request with the expected body', () => {
      axiosMock.onPut(endpoint).replyOnce(httpStatusCodes.OK, dummyResponse);

      const spy = jest.spyOn(axios, 'put');

      service.toggleServiceDesk(true);

      expect(spy).toHaveBeenCalledWith(endpoint, {
        service_desk_enabled: true,
      });

      spy.mockRestore();
    });
  });

  describe('updateTemplate', () => {
    it('makes a request to update template', () => {
      axiosMock.onPut(endpoint).replyOnce(httpStatusCodes.OK, dummyResponse);

      return service
        .updateTemplate(
          {
            selectedTemplate: 'Bug',
            outgoingName: 'GitLab Support Bot',
          },
          true,
        )
        .then(response => {
          expect(response.data).toEqual(dummyResponse);
        });
    });

    it('fails on error response', () => {
      axiosMock.onPut(endpoint).networkError();

      return service
        .updateTemplate(
          {
            selectedTemplate: 'Bug',
            outgoingName: 'GitLab Support Bot',
          },
          true,
        )
        .catch(error => {
          expect(error.message).toBe(errorMessage);
        });
    });

    it('makes a request with the expected body', () => {
      axiosMock.onPut(endpoint).replyOnce(httpStatusCodes.OK, dummyResponse);

      const spy = jest.spyOn(axios, 'put');

      service.updateTemplate(
        {
          selectedTemplate: 'Bug',
          outgoingName: 'GitLab Support Bot',
          projectKey: 'key',
        },
        true,
      );

      expect(spy).toHaveBeenCalledWith(endpoint, {
        issue_template_key: 'Bug',
        outgoing_name: 'GitLab Support Bot',
        project_key: 'key',
        service_desk_enabled: true,
      });

      spy.mockRestore();
    });
  });
});
