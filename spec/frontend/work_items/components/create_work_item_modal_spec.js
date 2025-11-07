import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { GlDisclosureDropdownItem, GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import CreateWorkItem from '~/work_items/components/create_work_item.vue';
import CreateWorkItemModal from '~/work_items/components/create_work_item_modal.vue';
import {
  CREATION_CONTEXT_LIST_ROUTE,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_KEY_RESULT,
  WORK_ITEM_TYPE_NAME_OBJECTIVE,
  WORK_ITEM_TYPE_NAME_REQUIREMENTS,
  WORK_ITEM_TYPE_NAME_TASK,
  WORK_ITEM_TYPE_NAME_TEST_CASE,
  WORK_ITEM_TYPE_NAME_TICKET,
  WORK_ITEM_TYPE_ROUTE_EPIC,
  WORK_ITEM_TYPE_ROUTE_ISSUE,
  WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
} from '~/work_items/constants';
import CreateWorkItemCancelConfirmationModal from '~/work_items/components/create_work_item_cancel_confirmation_modal.vue';

const showToast = jest.fn();

describe('CreateWorkItemModal', () => {
  useLocalStorageSpy();
  Vue.use(VueRouter);
  let wrapper;
  const router = new VueRouter({
    routes: [
      {
        path: `/`,
        name: 'home',
        component: CreateWorkItemModal,
      },
    ],
    mode: 'history',
    base: 'basePath',
  });

  const findTrigger = () => wrapper.find('[data-testid="new-epic-button"]');
  const findDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findCreateModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(CreateWorkItem);
  const findOpenInFullPageButton = () => wrapper.find('[data-testid="new-work-item-modal-link"]');
  const findCancelConfirmationModal = () =>
    wrapper.findComponent(CreateWorkItemCancelConfirmationModal);

  const createComponent = ({
    asDropdownItem = false,
    hideButton = false,
    preselectedWorkItemType = WORK_ITEM_TYPE_NAME_EPIC,
    relatedItem = null,
    alwaysShowWorkItemTypeSelect = false,
    namespaceFullName = 'GitLab.org / GitLab',
  } = {}) => {
    wrapper = shallowMount(CreateWorkItemModal, {
      propsData: {
        fullPath: 'full-path',
        creationContext: CREATION_CONTEXT_LIST_ROUTE,
        preselectedWorkItemType,
        asDropdownItem,
        hideButton,
        relatedItem,
        alwaysShowWorkItemTypeSelect,
        namespaceFullName,
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
      stubs: {
        GlModal,
      },
      router,
    });
  };

  beforeEach(() => {
    gon.current_user_id = 1;
  });

  afterEach(() => {
    localStorage.clear();
  });

  it('renders create-work-item component with preselectedWorkItemType prop set from localStorage draft', async () => {
    localStorage.setItem(
      'autosave/new-full-path-list-route-widgets-draft',
      JSON.stringify({ TYPE: { name: WORK_ITEM_TYPE_NAME_ISSUE } }),
    );

    createComponent();

    await waitForPromises();

    expect(findForm().props('preselectedWorkItemType')).toBe(WORK_ITEM_TYPE_NAME_ISSUE);
  });

  it('renders create-work-item component with preselectedWorkItemType prop set from localStorage draft with related item id', async () => {
    localStorage.setItem(
      'autosave/new-full-path-list-route-related-id-22-widgets-draft',
      JSON.stringify({ TYPE: { name: WORK_ITEM_TYPE_NAME_ISSUE } }),
    );

    createComponent({
      relatedItem: {
        id: 'gid://gitlab/WorkItem/22',
        type: 'Issue',
        reference: 'full-path#22',
        webUrl: '/full-path/-/issues/22',
      },
    });

    await waitForPromises();

    expect(findForm().props('preselectedWorkItemType')).toBe(WORK_ITEM_TYPE_NAME_ISSUE);
  });

  it('shows toast on workItemCreated', async () => {
    createComponent();

    await waitForPromises();
    const workItem = { webUrl: '/full-path/-/issues/22' };
    findForm().vm.$emit('workItemCreated', {
      webUrl: '/',
      workItem,
      workItemType: { name: 'Epic' },
    });

    expect(showToast).toHaveBeenCalledWith(
      'Epic created.',
      expect.objectContaining({
        action: {
          text: 'View details',
          onClick: expect.any(Function),
          href: workItem.webUrl,
        },
      }),
    );
  });

  describe('default trigger', () => {
    it('opens modal and prevents following link on click', async () => {
      createComponent();

      await waitForPromises();

      const mockEvent = { preventDefault: jest.fn() };
      findTrigger().vm.$emit('click', mockEvent);

      await nextTick();

      expect(findCreateModal().props('visible')).toBe(true);
      expect(findForm().props('namespaceFullName')).toBe('GitLab.org / GitLab');
      expect(mockEvent.preventDefault).toHaveBeenCalled();
    });

    it('does not open modal or prevent link default on ctrl+click', async () => {
      createComponent();

      await waitForPromises();

      const mockEvent = { preventDefault: jest.fn(), ctrlKey: true };
      findTrigger().vm.$emit('click', mockEvent);

      await nextTick();

      expect(findCreateModal().props('visible')).toBe(false);
      expect(mockEvent.preventDefault).not.toHaveBeenCalled();
    });

    it('does not open modal or prevent link default when user is signed out', async () => {
      window.gon = { current_user_id: undefined };
      createComponent();
      await waitForPromises();

      const mockEvent = { preventDefault: jest.fn(), ctrlKey: true };
      findTrigger().vm.$emit('click', mockEvent);
      await nextTick();

      expect(findCreateModal().props('visible')).toBe(false);
      expect(mockEvent.preventDefault).not.toHaveBeenCalled();
    });

    it('does not render when hideButton=true', () => {
      createComponent({ hideButton: true });

      expect(findTrigger().exists()).toBe(false);
    });

    it('has text of "New item" when the `alwaysShowWorkItemTypeSelect` prop is `true` and we also have a `preselectedWorkItemType`', () => {
      createComponent({ alwaysShowWorkItemTypeSelect: true, preselectedWorkItemType: 'ISSUE' });

      expect(findTrigger().text()).toBe('New item');
    });
  });

  describe('dropdown item trigger', () => {
    it('renders a dropdown item component', () => {
      createComponent({ asDropdownItem: true });

      expect(findDropdownItem().exists()).toBe(true);
    });
  });

  it('opens modal when visible prop updates to true', async () => {
    createComponent();

    expect(findCreateModal().props('visible')).toBe(false);

    await wrapper.setProps({ visible: true });

    expect(findCreateModal().props('visible')).toBe(true);
  });

  it('closes modal on cancel event from form', async () => {
    createComponent();

    await waitForPromises();

    await nextTick();

    findForm().vm.$emit('cancel');

    expect(findCreateModal().props('visible')).toBe(false);
  });

  it.each`
    workItemType                        | routeParamName
    ${WORK_ITEM_TYPE_NAME_EPIC}         | ${WORK_ITEM_TYPE_ROUTE_EPIC}
    ${WORK_ITEM_TYPE_NAME_ISSUE}        | ${WORK_ITEM_TYPE_ROUTE_ISSUE}
    ${WORK_ITEM_TYPE_NAME_INCIDENT}     | ${WORK_ITEM_TYPE_ROUTE_WORK_ITEM}
    ${WORK_ITEM_TYPE_NAME_KEY_RESULT}   | ${WORK_ITEM_TYPE_ROUTE_WORK_ITEM}
    ${WORK_ITEM_TYPE_NAME_OBJECTIVE}    | ${WORK_ITEM_TYPE_ROUTE_WORK_ITEM}
    ${WORK_ITEM_TYPE_NAME_REQUIREMENTS} | ${WORK_ITEM_TYPE_ROUTE_WORK_ITEM}
    ${WORK_ITEM_TYPE_NAME_TASK}         | ${WORK_ITEM_TYPE_ROUTE_WORK_ITEM}
    ${WORK_ITEM_TYPE_NAME_TEST_CASE}    | ${WORK_ITEM_TYPE_ROUTE_WORK_ITEM}
    ${WORK_ITEM_TYPE_NAME_TICKET}       | ${WORK_ITEM_TYPE_ROUTE_WORK_ITEM}
  `(
    `has link to new work item page in modal header for $workItemType and it appends initialCreationContext params to the url`,
    async ({ workItemType, routeParamName }) => {
      createComponent({ preselectedWorkItemType: workItemType });
      await waitForPromises();

      expect(findOpenInFullPageButton().attributes().href).toBe(
        `/full-path/-/${routeParamName}/new?initialCreationContext=${CREATION_CONTEXT_LIST_ROUTE}`,
      );
    },
  );

  describe('when there is a related item', () => {
    beforeEach(async () => {
      createComponent({
        relatedItem: {
          id: 'gid://gitlab/WorkItem/843',
          type: 'Epic',
          reference: 'flightjs#53',
          webUrl: 'http://gdk.test:3000/flightjs/Flight',
        },
      });
      await waitForPromises();
      await nextTick();
    });

    it('appends the related item id and initialCreationContext params to the full page button href', () => {
      expect(findOpenInFullPageButton().attributes('href')).toBe(
        `/full-path/-/epics/new?related_item_id=gid://gitlab/WorkItem/843&initialCreationContext=${CREATION_CONTEXT_LIST_ROUTE}`,
      );
    });
  });

  describe('when "changeType" event is emitted', () => {
    it('updates the selected type', async () => {
      createComponent();

      expect(wrapper.find('h2').text()).toBe('New epic');

      findForm().vm.$emit('changeType', WORK_ITEM_TYPE_NAME_KEY_RESULT);
      await nextTick();
      findForm().vm.$emit('workItemCreated', { webUrl: '/', workItem: {} });

      expect(wrapper.find('h2').text()).toBe('New key result');
      expect(findTrigger().text()).toBe('New key result');
      expect(showToast).toHaveBeenCalledWith('Key result created.', expect.any(Object));
    });
  });

  describe('CreateWorkItemCancelConfirmationModal', () => {
    it('confirmation modal is rendered but not visible initially', () => {
      createComponent();

      expect(findCancelConfirmationModal().exists()).toBe(true);
      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
    });

    it('confirmation modal is displayed over create modal when user clicks cancel on the form', async () => {
      createComponent();

      await wrapper.setProps({ visible: true });
      expect(findCreateModal().props('visible')).toBe(true);

      findForm().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);
      expect(findCreateModal().props('visible')).toBe(true);
    });

    it('confirmation modal closes when user clicks "Continue Editing" and create modal continues visible', async () => {
      createComponent();

      await wrapper.setProps({ visible: true });
      expect(findCreateModal().props('visible')).toBe(true);

      findForm().vm.$emit('confirmCancel');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(true);

      findCancelConfirmationModal().vm.$emit('continueEditing');
      await nextTick();

      expect(findCancelConfirmationModal().props('isVisible')).toBe(false);
      expect(findCreateModal().props('visible')).toBe(true);
    });
  });
});
