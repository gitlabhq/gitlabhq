import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import StageComponent from '~/pipelines/components/stage.vue';
import eventHub from '~/pipelines/event_hub';
import { stageReply } from './mock_data';
import waitForPromises from 'helpers/wait_for_promises';

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

  const createComponent = (props = {}) => {
    wrapper = mount(StageComponent, {
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

    it('should render the received data and emit `clickedDropdown` event', () => {
      jest.spyOn(eventHub, '$emit');
      wrapper.find('button').trigger('click');

      return waitForPromises().then(() => {
        expect(wrapper.find('.js-builds-dropdown-container ul').text()).toContain(
          stageReply.latest_statuses[0].name,
        );

        expect(eventHub.$emit).toHaveBeenCalledWith('clickedDropdown');
      });
    });
  });

  describe('when request fails', () => {
    beforeEach(() => {
      mock.onGet('path.json').reply(500);
      createComponent();
    });

    it('should close the dropdown', () => {
      wrapper.setMethods({
        closeDropdown: jest.fn(),
        isDropdownOpen: jest.fn().mockReturnValue(false),
      });

      wrapper.find('button').trigger('click');

      return waitForPromises().then(() => {
        expect(wrapper.vm.closeDropdown).toHaveBeenCalled();
      });
    });
  });

  describe('update endpoint correctly', () => {
    beforeEach(() => {
      const copyStage = Object.assign({}, stageReply);
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
    });

    it('should update the stage to request the new endpoint provided', () => {
      return wrapper.vm
        .$nextTick()
        .then(() => {
          wrapper.find('button').trigger('click');
          return waitForPromises();
        })
        .then(() => {
          expect(wrapper.find('.js-builds-dropdown-container ul').text()).toContain(
            'this is the updated content',
          );
        });
    });
  });

  describe('pipelineActionRequestComplete', () => {
    beforeEach(() => {
      mock.onGet('path.json').reply(200, stageReply);

      mock.onPost(`${stageReply.latest_statuses[0].status.action.path}.json`).reply(200);

      createComponent({ type: 'PIPELINES_TABLE' });
    });

    describe('within pipeline table', () => {
      it('emits `refreshPipelinesTable` event when `pipelineActionRequestComplete` is triggered', () => {
        jest.spyOn(eventHub, '$emit');

        wrapper.find('button').trigger('click');

        return waitForPromises()
          .then(() => {
            wrapper.find('.js-ci-action').trigger('click');

            return waitForPromises();
          })
          .then(() => {
            expect(eventHub.$emit).toHaveBeenCalledWith('refreshPipelinesTable');
          });
      });
    });
  });
});
