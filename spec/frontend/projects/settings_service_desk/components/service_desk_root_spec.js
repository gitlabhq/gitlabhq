import { shallowMount, mount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import ServiceDeskRoot from '~/projects/settings_service_desk/components/service_desk_root.vue';
import axios from '~/lib/utils/axios_utils';
import httpStatusCodes from '~/lib/utils/http_status';

describe('ServiceDeskRoot', () => {
  const endpoint = '/gitlab-org/gitlab-test/service_desk';
  const initialIncomingEmail = 'servicedeskaddress@example.com';
  let axiosMock;
  let wrapper;
  let spy;

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
    if (spy) {
      spy.mockRestore();
    }
  });

  it('fetches incoming email when there is no incoming email provided', () => {
    axiosMock.onGet(endpoint).replyOnce(httpStatusCodes.OK);

    wrapper = shallowMount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: true,
        initialIncomingEmail: '',
        endpoint,
      },
    });

    return wrapper.vm
      .$nextTick()
      .then(waitForPromises)
      .then(() => {
        expect(axiosMock.history.get).toHaveLength(1);
      });
  });

  it('does not fetch incoming email when there is an incoming email provided', () => {
    axiosMock.onGet(endpoint).replyOnce(httpStatusCodes.OK);

    wrapper = shallowMount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: true,
        initialIncomingEmail,
        endpoint,
      },
    });

    return wrapper.vm
      .$nextTick()
      .then(waitForPromises)
      .then(() => {
        expect(axiosMock.history.get).toHaveLength(0);
      });
  });

  it('shows an error message when incoming email is not fetched correctly', () => {
    axiosMock.onGet(endpoint).networkError();

    wrapper = shallowMount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: true,
        initialIncomingEmail: '',
        endpoint,
      },
    });

    return wrapper.vm
      .$nextTick()
      .then(waitForPromises)
      .then(() => {
        expect(wrapper.html()).toContain(
          'An error occurred while fetching the Service Desk address.',
        );
      });
  });

  it('sends a request to toggle service desk off when the toggle is clicked from the on state', () => {
    axiosMock.onPut(endpoint).replyOnce(httpStatusCodes.OK);

    spy = jest.spyOn(axios, 'put');

    wrapper = mount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: true,
        initialIncomingEmail,
        endpoint,
      },
    });

    wrapper.find('button.gl-toggle').trigger('click');

    return wrapper.vm
      .$nextTick()
      .then(waitForPromises)
      .then(() => {
        expect(spy).toHaveBeenCalledWith(endpoint, { service_desk_enabled: false });
      });
  });

  it('sends a request to toggle service desk on when the toggle is clicked from the off state', () => {
    axiosMock.onPut(endpoint).replyOnce(httpStatusCodes.OK);

    spy = jest.spyOn(axios, 'put');

    wrapper = mount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: false,
        initialIncomingEmail: '',
        endpoint,
      },
    });

    wrapper.find('button.gl-toggle').trigger('click');

    return wrapper.vm.$nextTick(() => {
      expect(spy).toHaveBeenCalledWith(endpoint, { service_desk_enabled: true });
    });
  });

  it('shows an error message when there is an issue toggling service desk on', () => {
    axiosMock.onPut(endpoint).networkError();

    wrapper = mount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: false,
        initialIncomingEmail: '',
        endpoint,
      },
    });

    wrapper.find('button.gl-toggle').trigger('click');

    return wrapper.vm
      .$nextTick()
      .then(waitForPromises)
      .then(() => {
        expect(wrapper.html()).toContain('An error occurred while enabling Service Desk.');
      });
  });

  it('sends a request to update template when the "Save template" button is clicked', () => {
    axiosMock.onPut(endpoint).replyOnce(httpStatusCodes.OK);

    spy = jest.spyOn(axios, 'put');

    wrapper = mount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: true,
        endpoint,
        initialIncomingEmail,
        selectedTemplate: 'Bug',
        outgoingName: 'GitLab Support Bot',
        templates: ['Bug', 'Documentation'],
        projectKey: 'key',
      },
    });

    wrapper.find('button.btn-success').trigger('click');

    return wrapper.vm.$nextTick(() => {
      expect(spy).toHaveBeenCalledWith(endpoint, {
        issue_template_key: 'Bug',
        outgoing_name: 'GitLab Support Bot',
        project_key: 'key',
        service_desk_enabled: true,
      });
    });
  });

  it('saves the template when the "Save template" button is clicked', () => {
    axiosMock.onPut(endpoint).replyOnce(httpStatusCodes.OK);

    wrapper = mount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: true,
        endpoint,
        initialIncomingEmail,
        selectedTemplate: 'Bug',
        templates: ['Bug', 'Documentation'],
      },
    });

    wrapper.find('button.btn-success').trigger('click');

    return wrapper.vm
      .$nextTick()
      .then(waitForPromises)
      .then(() => {
        expect(wrapper.html()).toContain('Template was successfully saved.');
      });
  });

  it('shows an error message when there is an issue saving the template', () => {
    axiosMock.onPut(endpoint).networkError();

    wrapper = mount(ServiceDeskRoot, {
      propsData: {
        initialIsEnabled: true,
        endpoint,
        initialIncomingEmail,
        selectedTemplate: 'Bug',
        templates: ['Bug', 'Documentation'],
      },
    });

    wrapper.find('button.btn-success').trigger('click');

    return wrapper.vm
      .$nextTick()
      .then(waitForPromises)
      .then(() => {
        expect(wrapper.html()).toContain(
          'An error occurred while saving the template. Please check if the template exists.',
        );
      });
  });
});
