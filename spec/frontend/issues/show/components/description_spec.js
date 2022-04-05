import $ from 'jquery';
import { nextTick } from 'vue';
import '~/behaviors/markdown/render_gfm';
import { GlTooltip, GlModal } from '@gitlab/ui';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
import { mockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import Description from '~/issues/show/components/description.vue';
import { updateHistory } from '~/lib/utils/url_utility';
import TaskList from '~/task_list';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import CreateWorkItem from '~/work_items/pages/create_work_item.vue';
import {
  descriptionProps as initialProps,
  descriptionHtmlWithCheckboxes,
  descriptionHtmlWithTask,
} from '../mock_data/mock_data';

jest.mock('~/flash');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));
jest.mock('~/task_list');

const showModal = jest.fn();
const hideModal = jest.fn();
const $toast = {
  show: jest.fn(),
};

describe('Description component', () => {
  let wrapper;

  const findGfmContent = () => wrapper.find('[data-testid="gfm-content"]');
  const findTextarea = () => wrapper.find('[data-testid="textarea"]');
  const findTaskActionButtons = () => wrapper.findAll('.js-add-task');
  const findConvertToTaskButton = () => wrapper.find('.js-add-task');

  const findTooltips = () => wrapper.findAllComponents(GlTooltip);
  const findModal = () => wrapper.findComponent(GlModal);
  const findCreateWorkItem = () => wrapper.findComponent(CreateWorkItem);
  const findWorkItemDetailModal = () => wrapper.findComponent(WorkItemDetailModal);

  function createComponent({ props = {}, provide = {} } = {}) {
    wrapper = shallowMountExtended(Description, {
      propsData: {
        issueId: 1,
        ...initialProps,
        ...props,
      },
      provide,
      mocks: {
        $toast,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            show: showModal,
            hide: hideModal,
          },
        }),
      },
    });
  }

  beforeEach(() => {
    setWindowLocation(TEST_HOST);

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
    describe('empty description', () => {
      beforeEach(() => {
        createComponent({
          props: {
            descriptionHtml: '',
          },
          provide: {
            glFeatures: {
              workItems: true,
            },
          },
        });
        return nextTick();
      });

      it('renders without error', () => {
        expect(findTaskActionButtons()).toHaveLength(0);
      });
    });

    describe('description with checkboxes', () => {
      beforeEach(() => {
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
        return nextTick();
      });

      it('renders a list of hidden buttons corresponding to checkboxes in description HTML', () => {
        expect(findTaskActionButtons()).toHaveLength(3);
      });

      it('renders a list of tooltips corresponding to checkboxes in description HTML', () => {
        expect(findTooltips()).toHaveLength(3);
        expect(findTooltips().at(0).props('target')).toBe(
          findTaskActionButtons().at(0).attributes('id'),
        );
      });

      it('does not show a modal by default', () => {
        expect(findModal().props('visible')).toBe(false);
      });

      it('opens a modal when a button is clicked and displays correct title', async () => {
        await findConvertToTaskButton().trigger('click');
        expect(findCreateWorkItem().props('initialTitle').trim()).toBe('todo 1');
      });

      it('closes the modal on `closeCreateTaskModal` event', async () => {
        await findConvertToTaskButton().trigger('click');
        findCreateWorkItem().vm.$emit('closeModal');
        expect(hideModal).toHaveBeenCalled();
      });

      it('emits `updateDescription` on `onCreate` event', () => {
        const newDescription = `<p>New description</p>`;
        findCreateWorkItem().vm.$emit('onCreate', newDescription);
        expect(hideModal).toHaveBeenCalled();
        expect(wrapper.emitted('updateDescription')).toEqual([[newDescription]]);
      });

      it('shows toast after delete success', async () => {
        findWorkItemDetailModal().vm.$emit('workItemDeleted');

        expect($toast.show).toHaveBeenCalledWith('Work item deleted');
      });
    });

    describe('work items detail', () => {
      const findTaskLink = () => wrapper.find('a.gfm-issue');

      describe('when opening and closing', () => {
        beforeEach(() => {
          createComponent({
            props: {
              descriptionHtml: descriptionHtmlWithTask,
            },
            provide: {
              glFeatures: { workItems: true },
            },
          });
          return nextTick();
        });

        it('opens when task button is clicked', async () => {
          expect(findWorkItemDetailModal().props('visible')).toBe(false);

          await findTaskLink().trigger('click');

          expect(findWorkItemDetailModal().props('visible')).toBe(true);
          expect(updateHistory).toHaveBeenCalledWith({
            url: `${TEST_HOST}/?work_item_id=2`,
            replace: true,
          });
        });

        it('closes from an open state', async () => {
          await findTaskLink().trigger('click');

          expect(findWorkItemDetailModal().props('visible')).toBe(true);

          findWorkItemDetailModal().vm.$emit('close');
          await nextTick();

          expect(findWorkItemDetailModal().props('visible')).toBe(false);
          expect(updateHistory).toHaveBeenLastCalledWith({
            url: `${TEST_HOST}/`,
            replace: true,
          });
        });

        it('tracks when opened', async () => {
          const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

          await findTaskLink().trigger('click');

          expect(trackingSpy).toHaveBeenCalledWith(
            'workItems:show',
            'viewed_work_item_from_modal',
            {
              category: 'workItems:show',
              label: 'work_item_view',
              property: 'type_task',
            },
          );
        });
      });

      describe('when url query `work_item_id` exists', () => {
        it.each`
          behavior           | workItemId     | visible
          ${'opens'}         | ${'123'}       | ${true}
          ${'does not open'} | ${'123e'}      | ${false}
          ${'does not open'} | ${'12e3'}      | ${false}
          ${'does not open'} | ${'1e23'}      | ${false}
          ${'does not open'} | ${'x'}         | ${false}
          ${'does not open'} | ${'undefined'} | ${false}
        `(
          '$behavior when url contains `work_item_id=$workItemId`',
          async ({ workItemId, visible }) => {
            setWindowLocation(`?work_item_id=${workItemId}`);

            createComponent({
              props: { descriptionHtml: descriptionHtmlWithTask },
              provide: { glFeatures: { workItems: true } },
            });

            expect(findWorkItemDetailModal().props('visible')).toBe(visible);
          },
        );
      });
    });
  });
});
