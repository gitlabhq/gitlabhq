import { GlDropdown } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import PipelineStage from '~/pipelines/components/pipelines_list/pipeline_stage.vue';
import eventHub from '~/pipelines/event_hub';
import { stageReply } from '../../mock_data';

const dropdownPath = 'path.json';

describe('Pipelines stage component', () => {
  let wrapper;
  let mock;
  let glTooltipDirectiveMock;

  const createComponent = (props = {}) => {
    glTooltipDirectiveMock = jest.fn();
    wrapper = mount(PipelineStage, {
      attachTo: document.body,
      directives: {
        GlTooltip: glTooltipDirectiveMock,
      },
      propsData: {
        stage: {
          status: {
            group: 'success',
            icon: 'status_success',
            title: 'success',
          },
          dropdown_path: dropdownPath,
        },
        updateDropdown: false,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(eventHub, '$emit');
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;

    eventHub.$emit.mockRestore();
    mock.restore();
  });

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownToggle = () => wrapper.find('button.dropdown-toggle');
  const findDropdownMenu = () =>
    wrapper.find('[data-testid="mini-pipeline-graph-dropdown-menu-list"]');
  const findCiActionBtn = () => wrapper.find('.js-ci-action');
  const findMergeTrainWarning = () => wrapper.find('[data-testid="warning-message-merge-trains"]');

  const openStageDropdown = () => {
    findDropdownToggle().trigger('click');
    return new Promise((resolve) => {
      wrapper.vm.$root.$on('bv::dropdown::show', resolve);
    });
  };

  describe('default appearance', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets up the tooltip to not have a show delay animation', () => {
      expect(glTooltipDirectiveMock.mock.calls[0][1].modifiers.ds0).toBe(true);
    });

    it('should render a dropdown with the status icon', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findDropdownToggle().exists()).toBe(true);
      expect(wrapper.find('[data-testid="status_success_borderless-icon"]').exists()).toBe(true);
    });
  });

  describe('when update dropdown is changed', () => {
    beforeEach(() => {
      createComponent();
    });
  });

  describe('when user opens dropdown and stage request is successful', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(200, stageReply);
      createComponent();

      await openStageDropdown();
      await axios.waitForAll();
    });

    it('should render the received data and emit `clickedDropdown` event', async () => {
      expect(findDropdownMenu().text()).toContain(stageReply.latest_statuses[0].name);
      expect(eventHub.$emit).toHaveBeenCalledWith('clickedDropdown');
    });

    it('should refresh when updateDropdown is set to true', async () => {
      expect(mock.history.get).toHaveLength(1);

      wrapper.setProps({ updateDropdown: true });
      await axios.waitForAll();

      expect(mock.history.get).toHaveLength(2);
    });
  });

  describe('when user opens dropdown and stage request fails', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(500);
      createComponent();

      await openStageDropdown();
      await axios.waitForAll();
    });

    it('should close the dropdown', () => {
      expect(findDropdown().classes('show')).toBe(false);
    });
  });

  describe('update endpoint correctly', () => {
    beforeEach(async () => {
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
      await axios.waitForAll();
    });

    it('should update the stage to request the new endpoint provided', async () => {
      await openStageDropdown();
      await axios.waitForAll();

      expect(findDropdownMenu().text()).toContain('this is the updated content');
    });
  });

  describe('pipelineActionRequestComplete', () => {
    beforeEach(() => {
      mock.onGet(dropdownPath).reply(200, stageReply);
      mock.onPost(`${stageReply.latest_statuses[0].status.action.path}.json`).reply(200);

      createComponent();
    });

    const clickCiAction = async () => {
      await openStageDropdown();
      await axios.waitForAll();

      findCiActionBtn().trigger('click');
      await axios.waitForAll();
    };

    it('closes dropdown when job item action is clicked', async () => {
      const hidden = jest.fn();

      wrapper.vm.$root.$on('bv::dropdown::hide', hidden);

      expect(hidden).toHaveBeenCalledTimes(0);

      await clickCiAction();

      expect(hidden).toHaveBeenCalledTimes(1);
    });

    it('emits `pipelineActionRequestComplete` when job item action is clicked', async () => {
      await clickCiAction();

      expect(wrapper.emitted('pipelineActionRequestComplete')).toHaveLength(1);
    });
  });

  describe('With merge trains enabled', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(200, stageReply);
      createComponent({
        isMergeTrain: true,
      });

      await openStageDropdown();
      await axios.waitForAll();
    });

    it('shows a warning on the dropdown', () => {
      const warning = findMergeTrainWarning();

      expect(warning.text()).toBe('Merge train pipeline jobs can not be retried');
    });
  });

  describe('With merge trains disabled', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(200, stageReply);
      createComponent();

      await openStageDropdown();
      await axios.waitForAll();
    });

    it('does not show a warning on the dropdown', () => {
      const warning = findMergeTrainWarning();

      expect(warning.exists()).toBe(false);
    });
  });
});
