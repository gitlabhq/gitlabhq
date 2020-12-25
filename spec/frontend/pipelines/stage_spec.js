import 'bootstrap/js/dist/dropdown';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import StageComponent from '~/pipelines/components/pipelines_list/stage.vue';
import eventHub from '~/pipelines/event_hub';
import { stageReply } from './mock_data';

describe('Pipelines stage component', () => {
  let wrapper;
  let mock;

  const defaultProps = {
    stage: {
      status: {
        group: 'success',
        icon: 'status_success',
        title: 'success',
      },
      dropdown_path: 'path.json',
    },
    updateDropdown: false,
  };

  const isDropdownOpen = () => wrapper.classes('show');

  const createComponent = (props = {}) => {
    wrapper = mount(StageComponent, {
      attachTo: document.body,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render a dropdown with the status icon', () => {
      expect(wrapper.attributes('class')).toEqual('dropdown');
      expect(wrapper.find('svg').exists()).toBe(true);
      expect(wrapper.find('button').attributes('data-toggle')).toEqual('dropdown');
    });
  });

  describe('with successful request', () => {
    beforeEach(() => {
      mock.onGet('path.json').reply(200, stageReply);
      createComponent();
    });

    it('should render the received data and emit `clickedDropdown` event', async () => {
      jest.spyOn(eventHub, '$emit');
      wrapper.find('button').trigger('click');

      await axios.waitForAll();
      expect(wrapper.find('.js-builds-dropdown-container ul').text()).toContain(
        stageReply.latest_statuses[0].name,
      );

      expect(eventHub.$emit).toHaveBeenCalledWith('clickedDropdown');
    });
  });

  it('when request fails should close the dropdown', async () => {
    mock.onGet('path.json').reply(500);
    createComponent();
    wrapper.find({ ref: 'dropdown' }).trigger('click');
    expect(isDropdownOpen()).toBe(true);

    wrapper.find('button').trigger('click');
    await axios.waitForAll();

    expect(isDropdownOpen()).toBe(false);
  });

  describe('update endpoint correctly', () => {
    beforeEach(() => {
      const copyStage = { ...stageReply };
      copyStage.latest_statuses[0].name = 'this is the updated content';
      mock.onGet('bar.json').reply(200, copyStage);
      createComponent({
        stage: {
          status: {
            group: 'running',
            icon: 'status_running',
            title: 'running',
          },
          dropdown_path: 'bar.json',
        },
      });
      return axios.waitForAll();
    });

    it('should update the stage to request the new endpoint provided', async () => {
      wrapper.find('button').trigger('click');
      await axios.waitForAll();

      expect(wrapper.find('.js-builds-dropdown-container ul').text()).toContain(
        'this is the updated content',
      );
    });
  });

  describe('pipelineActionRequestComplete', () => {
    beforeEach(() => {
      mock.onGet('path.json').reply(200, stageReply);
      mock.onPost(`${stageReply.latest_statuses[0].status.action.path}.json`).reply(200);

      createComponent({ type: 'PIPELINES_TABLE' });
    });

    describe('within pipeline table', () => {
      it('emits `refreshPipelinesTable` event when `pipelineActionRequestComplete` is triggered', async () => {
        jest.spyOn(eventHub, '$emit');

        wrapper.find('button').trigger('click');
        await axios.waitForAll();

        wrapper.find('.js-ci-action').trigger('click');
        await axios.waitForAll();

        expect(eventHub.$emit).toHaveBeenCalledWith('refreshPipelinesTable');
      });
    });
  });
});
