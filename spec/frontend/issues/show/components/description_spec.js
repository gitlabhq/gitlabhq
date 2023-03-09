import $ from 'jquery';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import getIssueDetailsQuery from 'ee_else_ce/work_items/graphql/get_issue_details.query.graphql';
import setWindowLocation from 'helpers/set_window_location_helper';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
import { mockTracking } from 'helpers/tracking_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/flash';
import Description from '~/issues/show/components/description.vue';
import eventHub from '~/issues/show/event_hub';
import { updateHistory } from '~/lib/utils/url_utility';
import workItemQuery from '~/work_items/graphql/work_item.query.graphql';
import createWorkItemMutation from '~/work_items/graphql/create_work_item.mutation.graphql';
import workItemTypesQuery from '~/work_items/graphql/project_work_item_types.query.graphql';
import TaskList from '~/task_list';
import WorkItemDetailModal from '~/work_items/components/work_item_detail_modal.vue';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import {
  createWorkItemMutationErrorResponse,
  createWorkItemMutationResponse,
  getIssueDetailsResponse,
  projectWorkItemTypesQueryResponse,
} from 'jest/work_items/mock_data';
import {
  descriptionProps as initialProps,
  descriptionHtmlWithList,
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

const mockSpriteIcons = '/icons.svg';
const showModal = jest.fn();
const hideModal = jest.fn();
const showDetailsModal = jest.fn();
const $toast = {
  show: jest.fn(),
};

const issueDetailsResponse = getIssueDetailsResponse();
const workItemQueryResponse = {
  data: {
    workItem: null,
  },
};

const queryHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
const workItemTypesQueryHandler = jest.fn().mockResolvedValue(projectWorkItemTypesQueryResponse);

describe('Description component', () => {
  let wrapper;
  let originalGon;

  Vue.use(VueApollo);

  const findGfmContent = () => wrapper.find('[data-testid="gfm-content"]');
  const findTextarea = () => wrapper.find('[data-testid="textarea"]');
  const findListItems = () => findGfmContent().findAll('ul > li');
  const findTaskActionButtons = () => wrapper.findAll('.task-list-item-actions');
  const findTaskLink = () => wrapper.find('a.gfm-issue');
  const findModal = () => wrapper.findComponent(GlModal);
  const findWorkItemDetailModal = () => wrapper.findComponent(WorkItemDetailModal);

  function createComponent({
    props = {},
    provide,
    issueDetailsQueryHandler = jest.fn().mockResolvedValue(issueDetailsResponse),
    createWorkItemMutationHandler,
    ...options
  } = {}) {
    wrapper = shallowMountExtended(Description, {
      propsData: {
        issueId: 1,
        issueIid: 1,
        ...initialProps,
        ...props,
      },
      provide: {
        fullPath: 'gitlab-org/gitlab-test',
        hasIterationsFeature: true,
        ...provide,
      },
      apolloProvider: createMockApollo([
        [workItemQuery, queryHandler],
        [workItemTypesQuery, workItemTypesQueryHandler],
        [getIssueDetailsQuery, issueDetailsQueryHandler],
        [createWorkItemMutation, createWorkItemMutationHandler],
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
      ...options,
    });
  }

  beforeEach(() => {
    originalGon = window.gon;
    window.gon = { sprite_icons: mockSpriteIcons };

    setWindowLocation(TEST_HOST);

    if (!document.querySelector('.issuable-meta')) {
      const metaData = document.createElement('div');
      metaData.classList.add('issuable-meta');
      metaData.innerHTML =
        '<div class="flash-container"></div><span id="task_status"></span><span id="task_status_short"></span>';

      document.body.appendChild(metaData);
    }
  });

  afterAll(() => {
    window.gon = originalGon;

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

  describe('with list', () => {
    beforeEach(async () => {
      createComponent({
        props: {
          descriptionHtml: descriptionHtmlWithList,
        },
        attachTo: document.body,
      });
      await nextTick();
    });

    it('shows list items', () => {
      expect(findListItems()).toHaveLength(3);
    });

    it('shows list items drag icons', () => {
      const dragIcon = findListItems().at(0).find('.drag-icon');

      expect(dragIcon.classes()).toEqual(
        expect.arrayContaining(['s14', 'gl-icon', 'gl-cursor-grab', 'gl-opacity-0']),
      );
      expect(dragIcon.attributes()).toMatchObject({
        'aria-hidden': 'true',
        role: 'img',
      });
      expect(dragIcon.find('use').attributes()).toEqual({
        href: `${mockSpriteIcons}#grip`,
      });
    });
  });

  describe('empty description', () => {
    beforeEach(() => {
      createComponent({
        props: {
          descriptionHtml: '',
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
      });
      return nextTick();
    });

    it('renders a list of hidden buttons corresponding to checkboxes in description HTML', () => {
      expect(findTaskActionButtons()).toHaveLength(3);
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

  describe('task list item actions', () => {
    describe('converting the task list item to a task', () => {
      describe('when successful', () => {
        let createWorkItemMutationHandler;

        beforeEach(async () => {
          createWorkItemMutationHandler = jest
            .fn()
            .mockResolvedValue(createWorkItemMutationResponse);
          const descriptionText = `Tasks

1. [ ] item 1
   1. [ ] item 2

      paragraph text

      1. [ ] item 3
   1. [ ] item 4;`;
          createComponent({
            props: { descriptionText },
            createWorkItemMutationHandler,
          });
          await waitForPromises();

          eventHub.$emit('convert-task-list-item', '4:4-8:19');
          await waitForPromises();
        });

        it('emits an event to update the description with the deleted task list item omitted', () => {
          const newDescriptionText = `Tasks

1. [ ] item 1
   1. [ ] item 3
   1. [ ] item 4;`;

          expect(wrapper.emitted('saveDescription')).toEqual([[newDescriptionText]]);
        });

        it('calls a mutation to create a task', () => {
          const {
            confidential,
            iteration,
            milestone,
          } = issueDetailsResponse.data.workspace.issuable;
          expect(createWorkItemMutationHandler).toHaveBeenCalledWith({
            input: {
              confidential,
              description: '\nparagraph text\n',
              hierarchyWidget: {
                parentId: 'gid://gitlab/WorkItem/1',
              },
              iterationWidget: {
                iterationId: IS_EE ? iteration.id : null,
              },
              milestoneWidget: {
                milestoneId: milestone.id,
              },
              projectPath: 'gitlab-org/gitlab-test',
              title: 'item 2',
              workItemTypeId: 'gid://gitlab/WorkItems::Type/3',
            },
          });
        });

        it('shows a toast to confirm the creation of the task', () => {
          expect($toast.show).toHaveBeenCalledWith('Converted to task', expect.any(Object));
        });
      });

      describe('when unsuccessful', () => {
        beforeEach(async () => {
          createComponent({
            props: { descriptionText: 'description' },
            createWorkItemMutationHandler: jest
              .fn()
              .mockResolvedValue(createWorkItemMutationErrorResponse),
          });
          await waitForPromises();

          eventHub.$emit('convert-task-list-item', '1:1-1:11');
          await waitForPromises();
        });

        it('shows an alert with an error message', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'Something went wrong when creating task. Please try again.',
            error: new Error('an error'),
            captureError: true,
          });
        });
      });
    });

    describe('deleting the task list item', () => {
      it('emits an event to update the description with the deleted task list item', () => {
        const descriptionText = `Tasks

1. [ ] item 1
   1. [ ] item 2
      1. [ ] item 3
   1. [ ] item 4;`;
        const newDescriptionText = `Tasks

1. [ ] item 1
   1. [ ] item 3
   1. [ ] item 4;`;
        createComponent({
          props: { descriptionText },
        });

        eventHub.$emit('delete-task-list-item', '4:4-5:19');

        expect(wrapper.emitted('saveDescription')).toEqual([[newDescriptionText]]);
      });
    });
  });

  describe('work items detail', () => {
    describe('when opening and closing', () => {
      beforeEach(() => {
        createComponent({
          props: {
            descriptionHtml: descriptionHtmlWithTask,
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
