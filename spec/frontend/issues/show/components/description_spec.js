import $ from 'jquery';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlTooltip, GlModal } from '@gitlab/ui';

import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
import { mockTracking } from 'helpers/tracking_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { createAlert } from '~/flash';
import Description from '~/issues/show/components/description.vue';
import { updateHistory } from '~/lib/utils/url_utility';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import workItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import createWorkItemFromTaskMutation from '~/work_items/graphql/create_work_item_from_task.mutation.graphql';
import TaskList from '~/task_list';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import {
  projectWorkItemTypesQueryResponse,
  createWorkItemFromTaskMutationResponse,
} from 'jest/work_items/mock_data';
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
jest.mock('~/behaviors/markdown/render_gfm');

const showModal = jest.fn();
const hideModal = jest.fn();
const showDetailsModal = jest.fn();
const $toast = {
  show: jest.fn(),
};

const workItemQueryResponse = {
  data: {
    workItem: null,
  },
};

const queryHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
const workItemTypesQueryHandler = jest.fn().mockResolvedValue(projectWorkItemTypesQueryResponse);
const createWorkItemFromTaskSuccessHandler = jest
  .fn()
  .mockResolvedValue(createWorkItemFromTaskMutationResponse);

describe('Description component', () => {
  let wrapper;

  Vue.use(VueApollo);

  const findGfmContent = () => wrapper.find('[data-testid="gfm-content"]');
  const findTextarea = () => wrapper.find('[data-testid="textarea"]');
  const findTaskActionButtons = () => wrapper.findAll('.js-add-task');
  const findConvertToTaskButton = () => wrapper.find('.js-add-task');
  const findTaskLink = () => wrapper.find('a.gfm-issue');

  const findTooltips = () => wrapper.findAllComponents(GlTooltip);
  const findModal = () => wrapper.findComponent(GlModal);
  const findWorkItemDetailModal = () => wrapper.findComponent(WorkItemDetailModal);

  function createComponent({
    props = {},
    provide,
    createWorkItemFromTaskHandler = createWorkItemFromTaskSuccessHandler,
  } = {}) {
    wrapper = shallowMountExtended(Description, {
      propsData: {
        issueId: 1,
        ...initialProps,
        ...props,
      },
      provide: {
        fullPath: 'gitlab-org/gitlab-test',
        ...provide,
      },
      apolloProvider: createMockApollo([
        [workItemQuery, queryHandler],
        [workItemTypesQuery, workItemTypesQueryHandler],
        [createWorkItemFromTaskMutation, createWorkItemFromTaskHandler],
      ]),
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
        WorkItemDetailModal: stubComponent(WorkItemDetailModal, {
          methods: {
            show: showDetailsModal,
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
    createComponent();

    await wrapper.setProps({
      descriptionHtml: 'changed',
    });

    expect(findGfmContent().exists()).toBe(true);
    expect(renderGFM).toHaveBeenCalled();
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
        '1/1 checklist item',
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

  describe('with work_items_create_from_markdown feature flag enabled', () => {
    describe('empty description', () => {
      beforeEach(() => {
        createComponent({
          props: {
            descriptionHtml: '',
          },
          provide: {
            glFeatures: {
              workItemsCreateFromMarkdown: true,
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
              workItemsCreateFromMarkdown: true,
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
        expect(findModal().exists()).toBe(false);
      });

      it('shows toast after delete success', async () => {
        const newDesc = 'description';
        findWorkItemDetailModal().vm.$emit('workItemDeleted', newDesc);

        expect(wrapper.emitted('updateDescription')).toEqual([[newDesc]]);
        expect($toast.show).toHaveBeenCalledWith('Task deleted');
      });
    });

    describe('creating work item from checklist item', () => {
      it('emits `updateDescription` after creating new work item', async () => {
        createComponent({
          props: {
            descriptionHtml: descriptionHtmlWithCheckboxes,
          },
          provide: {
            glFeatures: {
              workItemsCreateFromMarkdown: true,
            },
          },
        });

        const newDescription = `<p>New description</p>`;

        await findConvertToTaskButton().trigger('click');

        await waitForPromises();

        expect(wrapper.emitted('updateDescription')).toEqual([[newDescription]]);
      });

      it('shows flash message when creating task fails', async () => {
        createComponent({
          props: {
            descriptionHtml: descriptionHtmlWithCheckboxes,
          },
          provide: {
            glFeatures: {
              workItemsCreateFromMarkdown: true,
            },
          },
          createWorkItemFromTaskHandler: jest.fn().mockRejectedValue({}),
        });

        await findConvertToTaskButton().trigger('click');

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith(
          expect.objectContaining({
            message: 'Something went wrong when creating task. Please try again.',
          }),
        );
      });
    });

    describe('work items detail', () => {
      describe('when opening and closing', () => {
        beforeEach(() => {
          createComponent({
            props: {
              descriptionHtml: descriptionHtmlWithTask,
            },
            provide: {
              glFeatures: { workItemsCreateFromMarkdown: true },
            },
          });
          return nextTick();
        });

        it('opens when task button is clicked', async () => {
          await findTaskLink().trigger('click');

          expect(showDetailsModal).toHaveBeenCalled();
          expect(updateHistory).toHaveBeenCalledWith({
            url: `${TEST_HOST}/?work_item_id=2`,
            replace: true,
          });
        });

        it('closes from an open state', async () => {
          await findTaskLink().trigger('click');

          findWorkItemDetailModal().vm.$emit('close');
          await nextTick();

          expect(updateHistory).toHaveBeenLastCalledWith({
            url: `${TEST_HOST}/`,
            replace: true,
          });
        });

        it('tracks when opened', async () => {
          const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

          await findTaskLink().trigger('click');

          expect(trackingSpy).toHaveBeenCalledWith(
            TRACKING_CATEGORY_SHOW,
            'viewed_work_item_from_modal',
            {
              category: TRACKING_CATEGORY_SHOW,
              label: 'work_item_view',
              property: 'type_task',
            },
          );
        });
      });

      describe('when url query `work_item_id` exists', () => {
        it.each`
          behavior           | workItemId     | modalOpened
          ${'opens'}         | ${'2'}         | ${1}
          ${'does not open'} | ${'123'}       | ${0}
          ${'does not open'} | ${'123e'}      | ${0}
          ${'does not open'} | ${'12e3'}      | ${0}
          ${'does not open'} | ${'1e23'}      | ${0}
          ${'does not open'} | ${'x'}         | ${0}
          ${'does not open'} | ${'undefined'} | ${0}
        `(
          '$behavior when url contains `work_item_id=$workItemId`',
          async ({ workItemId, modalOpened }) => {
            setWindowLocation(`?work_item_id=${workItemId}`);

            createComponent({
              props: { descriptionHtml: descriptionHtmlWithTask },
              provide: { glFeatures: { workItemsCreateFromMarkdown: true } },
            });

            expect(showDetailsModal).toHaveBeenCalledTimes(modalOpened);
          },
        );
      });
    });

    describe('when hovering task links', () => {
      beforeEach(() => {
        createComponent({
          props: {
            descriptionHtml: descriptionHtmlWithTask,
          },
          provide: {
            glFeatures: { workItemsCreateFromMarkdown: true },
          },
        });
        return nextTick();
      });

      it('prefetches work item detail after work item link is hovered for 150ms', async () => {
        await findTaskLink().trigger('mouseover');
        jest.advanceTimersByTime(150);
        await waitForPromises();

        expect(queryHandler).toHaveBeenCalledWith({
          id: 'gid://gitlab/WorkItem/2',
        });
      });

      it('does not work item detail after work item link is hovered for less than 150ms', async () => {
        await findTaskLink().trigger('mouseover');
        await findTaskLink().trigger('mouseout');
        jest.advanceTimersByTime(150);
        await waitForPromises();

        expect(queryHandler).not.toHaveBeenCalled();
      });
    });
  });
});
