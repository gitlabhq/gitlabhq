import { shallowMount } from '@vue/test-utils';
import { GlModal, GlSprintf } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';

import { TEST_HOST } from 'helpers/test_constants';
import { stubComponent } from 'helpers/stub_component';

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

  afterEach(() => {
    axiosMock.reset();
  });

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

    it('redirects when a label is promoted', async () => {
      const responseURL = `${TEST_HOST}/dummy/endpoint`;
      axiosMock.onPost(labelMockData.url).reply(HTTP_STATUS_OK, { url: responseURL });

      wrapper.findComponent(GlModal).vm.$emit('primary');

      expect(eventHub.$emit).toHaveBeenCalledWith(
        'promoteLabelModal.requestStarted',
        labelMockData.url,
      );

      await axios.waitForAll();

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

      wrapper.findComponent(GlModal).vm.$emit('primary');

      await axios.waitForAll();

      expect(eventHub.$emit).toHaveBeenCalledWith('promoteLabelModal.requestFinished', {
        labelUrl: labelMockData.url,
        successful: false,
      });
    });
  });
});
