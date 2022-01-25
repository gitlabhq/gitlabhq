import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import ActionComponent from '~/pipelines/components/jobs_shared/action_component.vue';

describe('pipeline graph action component', () => {
  let wrapper;
  let mock;
  const findButton = () => wrapper.find(GlButton);

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onPost('foo.json').reply(200);

    wrapper = mount(ActionComponent, {
      propsData: {
        tooltipText: 'bar',
        link: 'foo',
        actionIcon: 'cancel',
      },
    });
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  it('should render the provided title as a bootstrap tooltip', () => {
    expect(wrapper.attributes('title')).toBe('bar');
  });

  it('should update bootstrap tooltip when title changes', async () => {
    wrapper.setProps({ tooltipText: 'changed' });

    await nextTick();
    expect(wrapper.attributes('title')).toBe('changed');
  });

  it('should render an svg', () => {
    expect(wrapper.find('.ci-action-icon-wrapper').exists()).toBe(true);
    expect(wrapper.find('svg').exists()).toBe(true);
  });

  describe('on click', () => {
    it('emits `pipelineActionRequestComplete` after a successful request', (done) => {
      jest.spyOn(wrapper.vm, '$emit');

      findButton().trigger('click');

      waitForPromises()
        .then(() => {
          expect(wrapper.vm.$emit).toHaveBeenCalledWith('pipelineActionRequestComplete');
          done();
        })
        .catch(done.fail);
    });

    it('renders a loading icon while waiting for request', async () => {
      findButton().trigger('click');

      await nextTick();
      expect(wrapper.find('.js-action-icon-loading').exists()).toBe(true);
    });
  });
});
