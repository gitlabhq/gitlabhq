import { GlDisclosureDropdown } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import LegacyPipelineStage from '~/ci/pipeline_mini_graph/legacy_pipeline_mini_graph/legacy_pipeline_stage.vue';
import eventHub from '~/ci/event_hub';
import waitForPromises from 'helpers/wait_for_promises';
import { legacyStageReply } from '../mock_data';

const dropdownPath = 'path.json';

describe('Pipelines stage component', () => {
  let wrapper;
  let mock;
  let glTooltipDirectiveMock;

  const createComponent = (props = {}) => {
    glTooltipDirectiveMock = jest.fn();
    wrapper = mount(LegacyPipelineStage, {
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
    eventHub.$emit.mockRestore();
    mock.restore();
    // eslint-disable-next-line @gitlab/vtu-no-explicit-wrapper-destroy
    wrapper.destroy();
  });

  const findCiActionBtn = () => wrapper.find('.js-ci-action');
  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownToggle = () =>
    wrapper.find('[data-testid="mini-pipeline-graph-dropdown-toggle"]');
  const findDropdownMenu = () =>
    wrapper.find('[data-testid="mini-pipeline-graph-dropdown-menu-list"]');
  const findDropdownMenuTitle = () =>
    wrapper.find('[data-testid="pipeline-stage-dropdown-menu-title"]');
  const findMergeTrainWarning = () => wrapper.find('[data-testid="warning-message-merge-trains"]');
  const findLoadingState = () => wrapper.find('[data-testid="pipeline-stage-loading-state"]');

  const openStageDropdown = async () => {
    await findDropdownToggle().trigger('click');
    await waitForPromises();
    await nextTick();
  };

  describe('loading state', () => {
    beforeEach(async () => {
      createComponent({ updateDropdown: true });

      mock.onGet(dropdownPath).reply(HTTP_STATUS_OK, legacyStageReply);
      await findDropdownToggle().trigger('click');
    });

    it('displays loading state while jobs are being fetched', () => {
      expect(findLoadingState().exists()).toBe(true);
      expect(findLoadingState().text()).toBe(LegacyPipelineStage.i18n.loadingText);
    });

    it('does not display loading state after jobs have been fetched', async () => {
      await waitForPromises();
      await nextTick();

      expect(findLoadingState().exists()).toBe(false);
    });
  });

  describe('default appearance', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets up the tooltip to not have a show delay animation', () => {
      expect(glTooltipDirectiveMock.mock.calls[0][1].modifiers.ds0).toBe(true);
    });

    it('renders a dropdown with the status icon', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findDropdownToggle().exists()).toBe(true);
      expect(findCiIcon().exists()).toBe(true);
    });
  });

  describe('when user opens dropdown and stage request is successful', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(HTTP_STATUS_OK, legacyStageReply);
      createComponent();

      await openStageDropdown();
      await jest.runAllTimers();
      await axios.waitForAll();
    });

    it('renders the received data and emits the correct events', () => {
      expect(findDropdownMenu().text()).toContain(legacyStageReply.latest_statuses[0].name);
      expect(findDropdownMenuTitle().text()).toContain(legacyStageReply.name);
      expect(eventHub.$emit).toHaveBeenCalledWith('clickedDropdown');
      expect(wrapper.emitted('miniGraphStageClick')).toEqual([[]]);
    });

    it('refreshes when updateDropdown is set to true', async () => {
      expect(mock.history.get).toHaveLength(1);

      wrapper.setProps({ updateDropdown: true });
      await axios.waitForAll();

      expect(mock.history.get).toHaveLength(2);
    });
  });

  describe('when user opens dropdown and stage request fails', () => {
    it('should close the dropdown', async () => {
      mock.onGet(dropdownPath).reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
      createComponent();

      await openStageDropdown();
      await axios.waitForAll();
      await waitForPromises();

      expect(findDropdownToggle().attributes('aria-expanded')).toBe('false');
    });
  });

  describe('update endpoint correctly', () => {
    beforeEach(async () => {
      const copyStage = { ...legacyStageReply };
      copyStage.latest_statuses[0].name = 'this is the updated content';
      mock.onGet('bar.json').reply(HTTP_STATUS_OK, copyStage);
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
      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(findDropdownMenu().text()).toContain('this is the updated content');
    });
  });

  describe('job update in dropdown', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(HTTP_STATUS_OK, legacyStageReply);
      mock
        .onPost(`${legacyStageReply.latest_statuses[0].status.action.path}.json`)
        .reply(HTTP_STATUS_OK);

      createComponent();
      await waitForPromises();
      await nextTick();
    });

    const clickCiAction = async () => {
      await openStageDropdown();
      jest.runOnlyPendingTimers();
      await waitForPromises();

      await findCiActionBtn().trigger('click');
    };

    it('keeps dropdown open when job item action is clicked', async () => {
      await clickCiAction();
      await waitForPromises();

      expect(findDropdownToggle().attributes('aria-expanded')).toBe('true');
    });
  });

  describe('With merge trains enabled', () => {
    it('shows a warning on the dropdown', async () => {
      mock.onGet(dropdownPath).reply(HTTP_STATUS_OK, legacyStageReply);
      createComponent({
        isMergeTrain: true,
      });

      await openStageDropdown();
      jest.runOnlyPendingTimers();
      await waitForPromises();

      const warning = findMergeTrainWarning();

      expect(warning.text()).toBe('Merge train pipeline jobs can not be retried');
    });
  });

  describe('With merge trains disabled', () => {
    beforeEach(async () => {
      mock.onGet(dropdownPath).reply(HTTP_STATUS_OK, legacyStageReply);
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
