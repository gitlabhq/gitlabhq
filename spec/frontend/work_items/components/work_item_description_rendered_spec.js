import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { handleLocationHash } from '~/lib/utils/common_utils';
import eventHub from '~/issues/show/event_hub';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import WorkItemDescriptionRendered from '~/work_items/components/work_item_description_rendered.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { descriptionHtmlWithCheckboxes, descriptionTextWithCheckboxes } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/lib/utils/common_utils');

describe('WorkItemDescriptionRendered', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findCheckboxAtIndex = (index) => wrapper.findAll('input[type="checkbox"]').at(index);
  const findCreateWorkItemModal = () => wrapper.findComponent(CreateWorkItemModal);
  const findReadMore = () => wrapper.findComponent({ ref: 'show-all-btn' });
  const findDescription = () => wrapper.findByTestId('work-item-description');

  const defaultWorkItemDescription = {
    description: descriptionTextWithCheckboxes,
    descriptionHtml: descriptionHtmlWithCheckboxes,
  };

  const createComponent = ({
    workItemDescription = defaultWorkItemDescription,
    canEdit = false,
    isGroup = false,
    workItemType = 'ISSUE',
    withoutHeadingAnchors = false,
    disableTruncation = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemDescriptionRendered, {
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/818',
        workItemDescription,
        canEdit,
        isGroup,
        workItemType,
        withoutHeadingAnchors,
        disableTruncation,
      },
      provide: {
        fullPath: 'full/path',
      },
      stubs: {
        CreateWorkItemModal,
      },
    });
  };

  it('renders gfm', async () => {
    createComponent();

    await nextTick();

    expect(renderGFM).toHaveBeenCalled();
  });

  describe('with truncation', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();
    beforeEach(() => {
      createComponent({
        workItemDescription: {
          description: 'This is a long description',
          descriptionHtml: '<p>This is a long description</p>',
        },
      });
      const { element } = findDescription();
      jest.spyOn(element, 'clientHeight', 'get').mockImplementation(() => 800);
    });

    it('shows the untruncate action', () => {
      expect(findReadMore().exists()).toBe(true);
    });

    it('tracks untruncate action', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      await findReadMore().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith('expand_description_on_workitem', {}, undefined);
    });
  });

  describe('without truncation', () => {
    it('does not show the untruncate action', () => {
      createComponent({
        workItemDescription: {
          description: 'This is a long description',
          descriptionHtml: '<p>This is a long description</p>',
        },
        mockComputed: {
          isTruncated() {
            return false;
          },
        },
      });
      expect(findReadMore().exists()).toBe(false);
    });
  });

  describe('with anchor to description item', () => {
    const anchorHash = '#description-anchor';

    afterAll(() => {
      window.location.hash = '';
    });

    it('scrolls matching link into view', async () => {
      window.location.hash = anchorHash;
      createComponent({
        workItemDescription: {
          description: 'This is a long description',
          descriptionHtml: `<p>This is a long description</p><a href="${anchorHash}">Some anchor</a>`,
        },
        mockComputed: {
          isTruncated() {
            return true;
          },
        },
      });
      jest.spyOn(wrapper.vm, 'truncateLongDescription');

      await nextTick();

      expect(handleLocationHash).toHaveBeenCalled();
      expect(wrapper.vm.truncateLongDescription).not.toHaveBeenCalled();
    });
  });

  describe('`disableHeadingAnchors` prop', () => {
    const baseAnchorHtml =
      '<a id="user-content-this-is-an-anchor" class="anchor" aria-hidden="true" href="#this-is-an-anchor"></a>';
    const uninteractiveAnchorHtml =
      '<a id="user-content-this-is-an-anchor" class="anchor after:!gl-hidden" aria-hidden="true" href="#this-is-an-anchor"></a>';
    const baseHtml =
      '<h1 data-sourcepos="1:1-1:19" dir="auto">&#x000A;<a href="#this-is-an-anchor" aria-hidden="true" class="anchor" id="user-content-this-is-an-anchor"></a>This is an anchor</h1>';
    it('renders anchor links as normal when prop is `false`', () => {
      createComponent({
        withoutHeadingAnchors: false,
        workItemDescription: {
          description: 'This is an anchor',
          descriptionHtml: baseHtml,
        },
      });

      const renderedHtml = findDescription().html();
      expect(renderedHtml).toContain(baseAnchorHtml);
    });

    it('makes anchor links uninteractive when prop is `true`', () => {
      createComponent({
        withoutHeadingAnchors: true,
        workItemDescription: {
          description: 'This is an anchor',
          descriptionHtml: baseHtml,
        },
      });

      const renderedHtml = findDescription().html();
      expect(renderedHtml).toContain(uninteractiveAnchorHtml);
    });
  });

  describe('with checkboxes', () => {
    beforeEach(() => {
      createComponent({
        canEdit: true,
        workItemDescription: {
          description: `- [x] todo 1\n- [ ] todo 2`,
          descriptionHtml: `<ul dir="auto" class="task-list" data-sourcepos="1:1-4:0">
<li class="task-list-item" data-sourcepos="1:1-2:15">
<input checked="" class="task-list-item-checkbox" type="checkbox"> todo 1</li>
<li class="task-list-item" data-sourcepos="2:1-2:15">
<input class="task-list-item-checkbox" type="checkbox"> todo 2</li>
</ul>`,
        },
      });
    });

    it('checks unchecked checkbox', async () => {
      findCheckboxAtIndex(1).setChecked();

      await nextTick();

      const updatedDescription = `- [x] todo 1\n- [x] todo 2`;
      expect(wrapper.emitted('descriptionUpdated')).toEqual([[updatedDescription]]);
      expect(findReadMore().exists()).toBe(false);
    });

    it('disables checkbox while updating', async () => {
      findCheckboxAtIndex(1).setChecked();

      await nextTick();

      expect(findCheckboxAtIndex(1).attributes().disabled).toBeDefined();
    });

    it('unchecks checked checkbox', async () => {
      findCheckboxAtIndex(0).setChecked(false);

      await nextTick();

      const updatedDescription = `- [ ] todo 1\n- [ ] todo 2`;
      expect(wrapper.emitted('descriptionUpdated')).toEqual([[updatedDescription]]);
      expect(findReadMore().exists()).toBe(false);
    });
  });

  describe('task list item actions', () => {
    describe('converting the task list item', () => {
      it('opens modal to create work item and emits event to update description', async () => {
        const description = `Tasks

1. [ ] item 1
   1. [ ] item 2 with a really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really long title

      and more text

      and even more
      1. [ ] item 3
   1. [ ] item 4;`;
        const newDescription = `Tasks

1. [ ] item 1
   1. [ ] item 3
   1. [ ] item 4;`;
        createComponent({ workItemDescription: { description } });
        await waitForPromises();

        eventHub.$emit('convert-task-list-item', {
          id: 'gid://gitlab/WorkItem/818',
          sourcepos: '4:4-9:19',
        });
        await nextTick();

        expect(findCreateWorkItemModal().props()).toEqual({
          allowedWorkItemTypes: [],
          alwaysShowWorkItemTypeSelect: false,
          asDropdownItem: false,
          description: `lly really long title


and more text

and even more`,
          hideButton: true,
          isGroup: false,
          parentId: 'gid://gitlab/WorkItem/818',
          relatedItem: null,
          showProjectSelector: false,
          title:
            'item 2 with a really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really really rea',
          visible: true,
          workItemTypeName: 'TASK',
        });

        findCreateWorkItemModal().vm.$emit('workItemCreated');

        expect(wrapper.emitted('descriptionUpdated')).toEqual([[newDescription]]);

        findCreateWorkItemModal().vm.$emit('hideModal');
        await nextTick();

        expect(findCreateWorkItemModal().props('visible')).toBe(false);
      });

      describe('when work item epic', () => {
        it('converts task list item to child issue', async () => {
          const description = '1. [ ] item 1\n1. [ ] item 2';
          createComponent({
            isGroup: true,
            workItemType: 'Epic',
            workItemDescription: { description },
          });
          await waitForPromises();

          eventHub.$emit('convert-task-list-item', {
            id: 'gid://gitlab/WorkItem/818',
            sourcepos: '1:1-1:13',
          });
          await nextTick();

          expect(findCreateWorkItemModal().props()).toMatchObject({
            asDropdownItem: false,
            description: ``,
            hideButton: true,
            isGroup: true,
            parentId: 'gid://gitlab/WorkItem/818',
            showProjectSelector: true,
            title: 'item 1',
            visible: true,
            workItemTypeName: 'ISSUE',
          });
        });
      });

      describe('when work item issue', () => {
        it('converts task list item to child task', async () => {
          const description = '1. [ ] item 1\n1. [ ] item 2';
          createComponent({ workItemType: 'ISSUE', workItemDescription: { description } });
          await waitForPromises();

          eventHub.$emit('convert-task-list-item', {
            id: 'gid://gitlab/WorkItem/818',
            sourcepos: '1:1-1:13',
          });
          await nextTick();

          expect(findCreateWorkItemModal().props()).toMatchObject({
            asDropdownItem: false,
            description: ``,
            hideButton: true,
            isGroup: false,
            parentId: 'gid://gitlab/WorkItem/818',
            showProjectSelector: false,
            title: 'item 1',
            visible: true,
            workItemTypeName: 'TASK',
          });
        });
      });
    });

    describe('deleting the task list item', () => {
      it('emits an event to update the description with the deleted task list item', () => {
        const description = `Tasks

1. [ ] item 1
   1. [ ] item 2
      1. [ ] item 3
   1. [ ] item 4;`;
        const newDescription = `Tasks

1. [ ] item 1
   1. [ ] item 3
   1. [ ] item 4;`;
        createComponent({ workItemDescription: { description } });

        eventHub.$emit('delete-task-list-item', {
          id: 'gid://gitlab/WorkItem/818',
          sourcepos: '4:4-5:19',
        });

        expect(wrapper.emitted('descriptionUpdated')).toEqual([[newDescription]]);
      });
    });
  });
});
