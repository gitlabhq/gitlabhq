import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import ActionComponent from '~/ci/common/private/job_action_component.vue';

describe('pipeline graph action component', () => {
  let wrapper;
  let mock;

  const findButton = () => wrapper.findComponent(GlButton);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const defaultProps = {
    tooltipText: 'bar',
    link: 'foo',
    actionIcon: 'cancel',
  };

  const createComponent = ({ props } = {}) => {
    wrapper = mount(ActionComponent, {
      propsData: { ...defaultProps, ...props },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onPost('foo.json').reply(HTTP_STATUS_OK);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render the provided title as a bootstrap tooltip', () => {
      expect(findButton().attributes('title')).toBe('bar');
    });

    it('should update bootstrap tooltip when title changes', async () => {
      wrapper.setProps({ tooltipText: 'changed' });

      await nextTick();
      expect(findButton().attributes('title')).toBe('changed');
    });

    it('should render an svg', () => {
      expect(wrapper.find('.ci-action-icon-wrapper').exists()).toBe(true);
      expect(wrapper.find('svg').exists()).toBe(true);
    });
  });

  describe('on click', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits `pipelineActionRequestComplete` after a successful request', async () => {
      findButton().trigger('click');

      await waitForPromises();

      expect(wrapper.emitted().pipelineActionRequestComplete).toHaveLength(1);
    });

    it('displays a loading icon/disabled button while waiting for request', async () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findButton().props('disabled')).toBe(false);

      findButton().trigger('click');

      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findButton().props('disabled')).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findButton().props('disabled')).toBe(false);
    });
  });

  describe('when has a confirmation modal', () => {
    beforeEach(() => {
      createComponent({ props: { withConfirmationModal: true, shouldTriggerClick: false } });
    });

    describe('and a first click is initiated', () => {
      beforeEach(async () => {
        findButton().trigger('click');

        await waitForPromises();
      });

      it('emits `showActionConfirmationModal` event', () => {
        expect(wrapper.emitted().showActionConfirmationModal).toHaveLength(1);
      });

      it('does not emit `pipelineActionRequestComplete` event', () => {
        expect(wrapper.emitted().pipelineActionRequestComplete).toBeUndefined();
      });
    });

    describe('and the `shouldTriggerClick` value becomes true', () => {
      beforeEach(async () => {
        await wrapper.setProps({ shouldTriggerClick: true });
      });

      it('does not emit `showActionConfirmationModal` event', () => {
        expect(wrapper.emitted().showActionConfirmationModal).toBeUndefined();
      });

      it('emits `actionButtonClicked` event', () => {
        expect(wrapper.emitted().actionButtonClicked).toHaveLength(1);
      });
    });
  });
});
