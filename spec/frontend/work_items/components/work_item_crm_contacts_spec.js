import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';
import searchQuery from '~/crm/contacts/components/graphql/get_group_contacts.query.graphql';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import WorkItemCrmContacts from '~/work_items/components/work_item_crm_contacts.vue';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import {
  updateWorkItemMutationResponseFactory,
  updateWorkItemMutationErrorResponse,
  workItemByIidResponseFactory,
  getGroupCrmContactsResponse,
  mockCrmContacts,
} from 'ee_else_ce_jest/work_items/mock_data';

Vue.use(VueApollo);

const workItemId = 'gid://gitlab/WorkItem/10';
const mockItems = mockCrmContacts;

describe('WorkItemCrmContacts component', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const item1Id = mockItems[0].id;
  const item3Id = mockItems[2].id;

  const searchQuerySuccessHandler = jest
    .fn()
    .mockResolvedValue(getGroupCrmContactsResponse(mockItems));
  const errorHandler = jest.fn().mockRejectedValue('Error');
  const successUpdateWorkItemMutationHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponseFactory({ crmContacts: [mockItems[0]] }));

  const createComponent = ({
    searchQueryHandler = searchQuerySuccessHandler,
    updateWorkItemMutationHandler = successUpdateWorkItemMutationHandler,
    workItemIid = '1',
    items = [],
  } = {}) => {
    const workItemQueryResponse = workItemByIidResponseFactory({
      canUpdate: true,
      crmContacts: items,
    });
    const workItemQueryHandler = jest.fn().mockResolvedValue(workItemQueryResponse);

    wrapper = shallowMountExtended(WorkItemCrmContacts, {
      apolloProvider: createMockApollo([
        [searchQuery, searchQueryHandler],
        [updateWorkItemMutation, updateWorkItemMutationHandler],
        [workItemByIidQuery, workItemQueryHandler],
      ]),
      propsData: {
        workItemId,
        workItemIid,
        fullPath: 'test-project-path',
        workItemType: 'Task',
      },
    });
  };

  const findWorkItemSidebarDropdownWidget = () =>
    wrapper.findComponent(WorkItemSidebarDropdownWidget);
  const findAllItems = () => wrapper.findAllByTestId('contact');
  const findAllGroups = () => wrapper.findAllByTestId('organization');

  const showDropdown = () => {
    findWorkItemSidebarDropdownWidget().vm.$emit('dropdownShown');
  };

  const updateItems = async (items) => {
    findWorkItemSidebarDropdownWidget().vm.$emit('searchStarted');
    await waitForPromises();

    findWorkItemSidebarDropdownWidget().vm.$emit('updateValue', items);
  };

  const getMutationInput = (contactIds) => {
    return {
      input: {
        id: workItemId,
        crmContactsWidget: {
          contactIds,
        },
      },
    };
  };

  it('renders the work item sidebar dropdown widget with default props', async () => {
    createComponent();
    await waitForPromises();

    expect(findWorkItemSidebarDropdownWidget().props()).toMatchObject({
      dropdownLabel: 'Contacts',
      canUpdate: true,
      dropdownName: 'crm-contacts',
      updateInProgress: false,
      toggleDropdownText: '0 contacts',
      headerText: 'Select contacts',
      multiSelect: true,
      itemValue: [],
    });
    expect(findAllItems()).toHaveLength(0);
  });

  it('renders the items when they are already present, including inactive contacts', async () => {
    createComponent({ items: mockItems });
    await waitForPromises();

    expect(findWorkItemSidebarDropdownWidget().props('itemValue')).toStrictEqual(
      mockItems.map(({ id }) => id),
    );
    expect(findAllItems()).toHaveLength(mockItems.length);
    expect(findAllGroups()).toHaveLength(2);

    // Contacts as they appear in the dropdown are sorted by org name,
    // then by first name, so we need to manually check the items
    // in the correct order instead of just looping through the mock items

    const firstItemText = findAllItems().at(0).text();
    expect(firstItemText).toContain("Jenee O'Reilly");
    expect(firstItemText).toContain("Jenee.O'Reilly-12@example.org");
    expect(firstItemText).toContain('Anderson LLC-4');

    const secondItemText = findAllItems().at(1).text();
    expect(secondItemText).toContain('Kassie Oberbrunner');
    expect(secondItemText).toContain('Kassie.Oberbrunner-15@example.org');
    expect(secondItemText).toContain('Anderson LLC-4');

    const thirdItemText = findAllItems().at(2).text();
    expect(thirdItemText).toContain('Another Inactive Contact');
    expect(thirdItemText).toContain('second-inactive-contact@example.org');

    const fourthItemText = findAllItems().at(3).text();
    expect(fourthItemText).toContain('Inactive Contact');
    expect(fourthItemText).toContain('inactive-contact@example.org');

    const fifthItemText = findAllItems().at(4).text();
    expect(fifthItemText).toContain('Liza Osinski');
    expect(fifthItemText).toContain('Liza.Osinski-31@example.org');
  });

  it.each`
    expectedAssertion                                                  | searchTerm  | handler                                                                     | result
    ${'when dropdown is shown'}                                        | ${''}       | ${searchQuerySuccessHandler}                                                | ${3}
    ${'when correct input is entered'}                                 | ${'Item 1'} | ${jest.fn().mockResolvedValue(getGroupCrmContactsResponse([mockItems[0]]))} | ${1}
    ${'and shows no matching results when incorrect input is entered'} | ${'Item 2'} | ${jest.fn().mockResolvedValue(getGroupCrmContactsResponse([]))}             | ${0}
  `('calls search label query $expectedAssertion', async ({ searchTerm, result, handler }) => {
    createComponent({
      searchQueryHandler: handler,
    });

    showDropdown();
    await findWorkItemSidebarDropdownWidget().vm.$emit('searchStarted', searchTerm);

    expect(findWorkItemSidebarDropdownWidget().props('loading')).toBe(true);

    await waitForPromises();

    expect(findWorkItemSidebarDropdownWidget().props('loading')).toBe(false);

    expect(
      findWorkItemSidebarDropdownWidget()
        .props('listItems')
        .flatMap(({ options }) => options),
    ).toHaveLength(result);
    expect(handler).toHaveBeenCalledWith({
      groupFullPath: 'test-project-path',
      searchTerm,
      nextPageCursor: '',
      prevPageCursor: '',
    });
  });

  it('emits error event if search query fails', async () => {
    createComponent({ searchQueryHandler: errorHandler });
    showDropdown();
    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([
      ['Something went wrong when fetching CRM contacts. Please try again.'],
    ]);
  });

  it('update items when items are updated', async () => {
    createComponent();
    showDropdown();
    updateItems([item1Id]);
    await waitForPromises();

    expect(successUpdateWorkItemMutationHandler).toHaveBeenCalledWith(getMutationInput([item1Id]));
  });

  it('clears all items when updateValue has no items', async () => {
    createComponent();
    findWorkItemSidebarDropdownWidget().vm.$emit('updateValue', []);
    await waitForPromises();

    expect(successUpdateWorkItemMutationHandler).toHaveBeenCalledWith(getMutationInput([]));
  });

  it('only returns active contacts or selected items when searching', async () => {
    const activeContact = mockItems.filter(
      (item) => item.email === "Jenee.O'Reilly-12@example.org",
    )[0];
    const inactiveContact = mockItems.filter(
      (item) => item.email === 'inactive-contact@example.org',
    )[0];

    createComponent({
      items: [activeContact, inactiveContact],
    });

    showDropdown();
    await waitForPromises();

    expect(findWorkItemSidebarDropdownWidget().props('listItems')).toEqual([
      {
        text: 'Selected',
        options: [
          // Inactive contact is selected and is shown in the "Selected" section
          // Note that contacts are sorted by org name, then by first name,
          // so the inactive contact is shown first
          {
            value: 'gid://gitlab/CustomerRelations::Contact/233',
            text: 'Inactive Contact',
          },
          {
            value: 'gid://gitlab/CustomerRelations::Contact/213',
            text: "Jenee O'Reilly",
          },
        ],
      },
      // Only active contacts are shown outside of the "Selected" section
      {
        text: 'Anderson LLC-4',
        options: [
          {
            value: 'gid://gitlab/CustomerRelations::Contact/216',
            text: 'Kassie Oberbrunner',
          },
        ],
      },
      {
        text: 'No organization',
        options: [
          {
            value: 'gid://gitlab/CustomerRelations::Contact/232',
            text: 'Liza Osinski',
          },
        ],
      },
    ]);
  });

  it('shows selected items, then organizations then orphans', async () => {
    createComponent();
    updateItems([item1Id, item3Id]);
    await waitForPromises();
    showDropdown();

    const [item1, item2, item3] = mockItems;

    const selected = [{ text: `${item1.firstName} ${item1.lastName}`, value: item1.id }];
    const unselected = [{ text: `${item2.firstName} ${item2.lastName}`, value: item2.id }];
    const orphans = [{ text: `${item3.firstName} ${item3.lastName}`, value: item3.id }];

    expect(findWorkItemSidebarDropdownWidget().props('listItems')).toEqual([
      { options: selected, text: 'Selected' },
      { options: unselected, text: 'Anderson LLC-4' },
      { options: orphans, text: 'No organization' },
    ]);
  });

  describe('tracking', () => {
    let trackingSpy;

    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      trackingSpy = null;
    });

    it('tracks editing the items on dropdown widget updateValue', async () => {
      showDropdown();
      updateItems([item1Id]);

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, 'updated_contacts', {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_contact',
        property: 'type_Task',
      });
    });
  });

  it.each`
    errorType          | expectedErrorMessage                                                      | failureHandler
    ${'graphql error'} | ${'Something went wrong while updating the work item. Please try again.'} | ${jest.fn().mockResolvedValue(updateWorkItemMutationErrorResponse)}
    ${'network error'} | ${'Something went wrong while updating the work item. Please try again.'} | ${jest.fn().mockRejectedValue(new Error())}
  `(
    'emits an error when there is a $errorType',
    async ({ expectedErrorMessage, failureHandler }) => {
      createComponent({
        updateWorkItemMutationHandler: failureHandler,
      });

      updateItems([item1Id]);

      await waitForPromises();

      expect(wrapper.emitted('error')).toEqual([[expectedErrorMessage]]);
    },
  );
});
