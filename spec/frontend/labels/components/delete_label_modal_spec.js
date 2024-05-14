import { GlModal } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeleteLabelModal from '~/labels/components/delete_label_modal.vue';
import eventHub, {
  EVENT_DELETE_LABEL_MODAL_SUCCESS,
  EVENT_OPEN_DELETE_LABEL_MODAL,
} from '~/labels/event_hub';

describe('~/labels/components/delete_label_modal', () => {
  let wrapper;

  const openEventData = {
    labelId: '1',
    labelName: 'label 1',
    subjectName: 'GitLab Org',
    destroyPath: `${TEST_HOST}/1`,
  };
  const mountComponent = (propsData = {}) => {
    wrapper = mountExtended(DeleteLabelModal, {
      propsData: {
        ...propsData,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });

    eventHub.$emit(EVENT_OPEN_DELETE_LABEL_MODAL, openEventData);
  };

  afterEach(() => {
    eventHub.dispose();
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteButton = () => wrapper.findByTestId('delete-button');

  describe('when modal data is set', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders GlModal', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('displays the label name and subject name', () => {
      expect(findModal().text()).toContain(
        `label 1 will be permanently deleted from GitLab Org. This cannot be undone`,
      );
    });

    it('passes the destroyPath to the button', () => {
      expect(findDeleteButton().attributes('href')).toBe('http://test.host/1');
    });
  });

  describe('when modal uses remote action', () => {
    beforeEach(() => {
      mountComponent({ remoteDestroy: true });
    });

    it('calls delete endpoint', async () => {
      jest.spyOn(axios, 'delete').mockImplementation((url) => {
        expect(url).toBe(`${openEventData.destroyPath}.js`);
        return Promise.resolve({});
      });
      jest.spyOn(eventHub, '$emit');

      findDeleteButton().trigger('click');

      await waitForPromises();

      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_DELETE_LABEL_MODAL_SUCCESS,
        openEventData.labelId,
      );
    });
  });
});
