import { shallowMount } from '@vue/test-utils';
import { GlModal, GlSprintf } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';

import { TEST_HOST } from 'helpers/test_constants';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import * as urlUtils from '~/lib/utils/url_utility';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import PromoteLabelModal from '~/labels/components/promote_label_modal.vue';
import eventHub from '~/labels/event_hub';

describe('Promote label modal', () => {
  let wrapper;
  let axiosMock;

  const labelMockData = {
    labelTitle: 'Documentation',
    labelColor: 'rgb(92, 184, 92)',
    labelTextColor: 'rgb(255, 255, 255)',
    url: `${TEST_HOST}/dummy/promote/labels`,
    groupName: 'group',
  };

  const createComponent = () => {
    wrapper = shallowMount(PromoteLabelModal, {
      propsData: labelMockData,
      stubs: {
        GlSprintf,
        GlModal: stubComponent(GlModal, {
          template: `<div><slot name="modal-title"></slot><slot></slot></div>`,
        }),
      },
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    createComponent();
  });

  const findModal = () => wrapper.findComponent(GlModal);

  describe('Modal title and description', () => {
    it('contains the proper description', () => {
      expect(wrapper.text()).toContain(
        `Promoting ${labelMockData.labelTitle} will make it available for all projects inside ${labelMockData.groupName}`,
      );
    });

    it('contains a label span with the color', () => {
      const label = wrapper.find('.modal-title-with-label .label');

      expect(label.element.style.backgroundColor).toBe(labelMockData.labelColor);
      expect(label.element.style.color).toBe(labelMockData.labelTextColor);
      expect(label.text()).toBe(labelMockData.labelTitle);
    });
  });

  describe('When requesting a label promotion', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation(() => {});
    });

    it('calls promote api with right params', async () => {
      const getParameterByNameSpy = jest.spyOn(urlUtils, 'getParameterByName').mockReturnValue('2');

      findModal().vm.$emit('primary');
      await waitForPromises();
      const request = axiosMock.history.post.find((req) => req.url === labelMockData.url);

      expect(request).toBeDefined();
      expect(getParameterByNameSpy).toHaveBeenCalledWith('page');
      expect(JSON.parse(request.data)).toEqual({ params: { format: 'json' }, page: '2' });
    });

    it('redirects when a label is promoted', async () => {
      const responseURL = `${TEST_HOST}/dummy/endpoint`;
      axiosMock.onPost(labelMockData.url).reply(HTTP_STATUS_OK, { url: responseURL });

      findModal().vm.$emit('primary');

      expect(eventHub.$emit).toHaveBeenCalledWith(
        'promoteLabelModal.requestStarted',
        labelMockData.url,
      );

      await waitForPromises();

      expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestFinished', {
        labelUrl: labelMockData.url,
        successful: true,
      });
    });

    it('displays an error if promoting a label failed', async () => {
      const dummyError = new Error('promoting label failed');
      dummyError.response = { status: HTTP_STATUS_INTERNAL_SERVER_ERROR };
      axiosMock
        .onPost(labelMockData.url)
        .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, { error: dummyError });

      findModal().vm.$emit('primary');

      await waitForPromises();

      expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestFinished', {
        labelUrl: labelMockData.url,
        successful: false,
      });
    });
  });
});
