import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import ActionComponent from '~/pipelines/components/graph/action_component.vue';

describe('pipeline graph action component', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onPost('foo.json').reply(200);

    wrapper = mount(ActionComponent, {
      propsData: {
        tooltipText: 'bar',
        link: 'foo',
        actionIcon: 'cancel',
      },
      attachToDocument: true,
    });
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  it('should render the provided title as a bootstrap tooltip', () => {
    expect(wrapper.attributes('title')).toBe('bar');
  });

  it('should update bootstrap tooltip when title changes', done => {
    wrapper.setProps({ tooltipText: 'changed' });

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(wrapper.attributes('title')).toBe('changed');
      })
      .then(done)
      .catch(done.fail);
  });

  it('should render an svg', () => {
    expect(wrapper.find('.ci-action-icon-wrapper')).toBeDefined();
    expect(wrapper.find('svg')).toBeDefined();
  });

  describe('on click', () => {
    it('emits `pipelineActionRequestComplete` after a successful request', done => {
      jest.spyOn(wrapper.vm, '$emit');

      wrapper.find('button').trigger('click');

      waitForPromises()
        .then(() => {
          expect(wrapper.vm.$emit).toHaveBeenCalledWith('pipelineActionRequestComplete');
          done();
        })
        .catch(done.fail);
    });

    it('renders a loading icon while waiting for request', done => {
      wrapper.find('button').trigger('click');

      wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.js-action-icon-loading').exists()).toBe(true);
        done();
      });
    });
  });
});
