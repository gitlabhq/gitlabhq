import $ from 'jquery';
import { nextTick } from 'vue';
import '~/behaviors/markdown/render_gfm';
import { GlPopover, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
import Description from '~/issues/show/components/description.vue';
import TaskList from '~/task_list';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import {
  descriptionProps as initialProps,
  descriptionHtmlWithCheckboxes,
} from '../mock_data/mock_data';

jest.mock('~/task_list');

const showModal = jest.fn();
const hideModal = jest.fn();

describe('Description component', () => {
  let wrapper;

  const findGfmContent = () => wrapper.find('[data-testid="gfm-content"]');
  const findTextarea = () => wrapper.find('[data-testid="textarea"]');
  const findTaskActionButtons = () => wrapper.findAll('.js-add-task');
  const findConvertToTaskButton = () => wrapper.find('[data-testid="convert-to-task"]');
  const findTaskSvg = () => wrapper.find('[data-testid="issue-open-m-icon"]');

  const findPopovers = () => wrapper.findAllComponents(GlPopover);
  const findModal = () => wrapper.findComponent(GlModal);
  const findCreateWorkItem = () => wrapper.findComponent(CreateWorkItem);

  function createComponent({ props = {}, provide = {} } = {}) {
    wrapper = shallowMount(Description, {
      propsData: {
        ...initialProps,
        ...props,
      },
      provide,
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            show: showModal,
            hide: hideModal,
          },
        }),
        GlPopover,
      },
    });
  }

  beforeEach(() => {
    if (!document.querySelector('.issuable-meta')) {
      const metaData = document.createElement('div');
      metaData.classList.add('issuable-meta');
      metaData.innerHTML =
        '<div class="flash-container"></div><span id="task_status"></span><span id="task_status_short"></span>';

      document.body.appendChild(metaData);
    }
  });

  afterEach(() => {
    wrapper.destroy();
  });

  afterAll(() => {
    $('.issuable-meta .flash-container').remove();
  });

  it('doesnt animate first description changes', async () => {
    createComponent();
    await wrapper.setProps({
      descriptionHtml: 'changed',
    });

    expect(findGfmContent().classes()).not.toContain('issue-realtime-pre-pulse');
  });

  it('animates description changes on live update', async () => {
    createComponent();
    await wrapper.setProps({
      descriptionHtml: 'changed',
    });

    expect(findGfmContent().classes()).not.toContain('issue-realtime-pre-pulse');

    await wrapper.setProps({
      descriptionHtml: 'changed second time',
    });

    expect(findGfmContent().classes()).toContain('issue-realtime-pre-pulse');

    await jest.runOnlyPendingTimers();

    expect(findGfmContent().classes()).toContain('issue-realtime-trigger-pulse');
  });

  it('applies syntax highlighting and math when description changed', async () => {
    const prototypeSpy = jest.spyOn($.prototype, 'renderGFM');
    createComponent();

    await wrapper.setProps({
      descriptionHtml: 'changed',
    });

    expect(findGfmContent().exists()).toBe(true);
    expect(prototypeSpy).toHaveBeenCalled();
  });

  it('sets data-update-url', () => {
    createComponent();
    expect(findTextarea().attributes('data-update-url')).toBe(TEST_HOST);
  });

  describe('TaskList', () => {
    beforeEach(() => {
      TaskList.mockClear();
    });

    it('re-inits the TaskList when description changed', () => {
      createComponent({
        props: {
          issuableType: 'issuableType',
        },
      });
      wrapper.setProps({
        descriptionHtml: 'changed',
      });

      expect(TaskList).toHaveBeenCalled();
    });

    it('does not re-init the TaskList when canUpdate is false', async () => {
      createComponent({
        props: {
          issuableType: 'issuableType',
          canUpdate: false,
        },
      });
      wrapper.setProps({
        descriptionHtml: 'changed',
      });

      expect(TaskList).not.toHaveBeenCalled();
    });

    it('calls with issuableType dataType', () => {
      createComponent({
        props: {
          issuableType: 'issuableType',
        },
      });
      wrapper.setProps({
        descriptionHtml: 'changed',
      });

      expect(TaskList).toHaveBeenCalledWith({
        dataType: 'issuableType',
        fieldName: 'description',
        selector: '.detail-page-description',
        onUpdate: expect.any(Function),
        onSuccess: expect.any(Function),
        onError: expect.any(Function),
        lockVersion: 0,
      });
    });
  });

  describe('taskStatus', () => {
    it('adds full taskStatus', async () => {
      createComponent({
        props: {
          taskStatus: '1 of 1',
        },
      });
      await nextTick();

      expect(document.querySelector('.issuable-meta #task_status').textContent.trim()).toBe(
        '1 of 1',
      );
    });

    it('adds short taskStatus', async () => {
      createComponent({
        props: {
          taskStatus: '1 of 1',
        },
      });
      await nextTick();

      expect(document.querySelector('.issuable-meta #task_status_short').textContent.trim()).toBe(
        '1/1 task',
      );
    });

    it('clears task status text when no tasks are present', async () => {
      createComponent({
        props: {
          taskStatus: '0 of 0',
        },
      });

      await nextTick();

      expect(document.querySelector('.issuable-meta #task_status').textContent.trim()).toBe('');
    });
  });

  describe('with work items feature flag is enabled', () => {
    beforeEach(async () => {
      createComponent({
        props: {
          descriptionHtml: descriptionHtmlWithCheckboxes,
        },
        provide: {
          glFeatures: {
            workItems: true,
          },
        },
      });
      await nextTick();
    });

    it('renders a list of hidden buttons corresponding to checkboxes in description HTML', () => {
      expect(findTaskActionButtons()).toHaveLength(3);
    });

    it('renders a list of popovers corresponding to checkboxes in description HTML', () => {
      expect(findPopovers()).toHaveLength(3);
      expect(findPopovers().at(0).props('target')).toBe(
        findTaskActionButtons().at(0).attributes('id'),
      );
    });

    it('does not show a modal by default', () => {
      expect(findModal().props('visible')).toBe(false);
    });

    it('opens a modal when a button on popover is clicked and displays correct title', async () => {
      findConvertToTaskButton().vm.$emit('click');
      expect(showModal).toHaveBeenCalled();
      await nextTick();
      expect(findCreateWorkItem().props('initialTitle').trim()).toBe('todo 1');
    });

    it('closes the modal on `closeCreateTaskModal` event', () => {
      findConvertToTaskButton().vm.$emit('click');
      findCreateWorkItem().vm.$emit('closeModal');
      expect(hideModal).toHaveBeenCalled();
    });

    it('updates description HTML on `onCreate` event', async () => {
      const newTitle = 'New title';
      findConvertToTaskButton().vm.$emit('click');
      findCreateWorkItem().vm.$emit('onCreate', newTitle);
      expect(hideModal).toHaveBeenCalled();
      await nextTick();

      expect(findTaskSvg().exists()).toBe(true);
      expect(wrapper.text()).toContain(newTitle);
    });
  });
});
