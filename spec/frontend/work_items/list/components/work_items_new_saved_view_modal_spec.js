import { nextTick } from 'vue';
import { GlForm, GlModal, GlAlert, GlFormRadio, GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemsNewSavedViewModal from '~/work_items/list/components/work_items_new_saved_view_modal.vue';
import { CREATED_DESC, UPDATED_DESC } from '~/work_items/list/constants';
import { SAVED_VIEW_VISIBILITY } from '~/work_items/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { saveSavedView } from 'ee_else_ce/work_items/list/utils';

jest.mock('ee_else_ce/work_items/list/utils', () => ({
  saveSavedView: jest.fn(),
}));

describe('WorkItemsNewSavedViewModal', () => {
  let wrapper;

  const successCreateResponse = {
    data: {
      workItemSavedViewCreate: {
        errors: [],
        savedView: {
          id: 'gid://gitlab/SavedView/1',
          name: 'Test View',
          description: 'Test Description',
          isPrivate: true,
          subscribed: true,
          filters: {},
          displaySettings: {},
          sort: CREATED_DESC,
          userPermissions: {
            updateSavedView: true,
            deleteSavedView: true,
          },
        },
      },
    },
  };

  const successUpdateResponse = {
    data: {
      workItemSavedViewUpdate: {
        errors: [],
        savedView: {
          id: 'gid://gitlab/WorkItems::SavedView/123',
          name: 'Updated View',
          description: 'Updated Description',
          isPrivate: true,
          subscribed: true,
          filters: {},
          displaySettings: {},
          sort: CREATED_DESC,
          userPermissions: {
            updateSavedView: true,
            deleteSavedView: true,
          },
        },
      },
    },
  };

  const existingSavedView = {
    id: 'gid://gitlab/WorkItems::SavedView/123',
    name: 'Existing View',
    description: 'Existing Description',
    isPrivate: false,
    subscribed: true,
    filters: {},
    displaySettings: {},
    sort: CREATED_DESC,
    userPermissions: {
      updateSavedView: true,
      deleteSavedView: true,
    },
  };

  const mockToastShow = jest.fn();

  const createComponent = ({ props, mockSavedView = null } = {}) => {
    wrapper = shallowMountExtended(WorkItemsNewSavedViewModal, {
      propsData: {
        show: true,
        fullPath: 'test-project-path',
        sortKey: CREATED_DESC,
        savedView: mockSavedView,
        filters: {},
        displaySettings: {},
        ...props,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
        $router: {
          push: jest.fn(),
        },
      },
      provide: {
        subscribedSavedViewLimit: 5,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(GlForm);
  const findTitleInput = () => wrapper.find('#saved-view-title');
  const findDescriptionInput = () => wrapper.find('#saved-view-description');
  const findVisibilityInputs = () => wrapper.findByTestId('saved-view-visibility');
  const findCreateButton = () => wrapper.findByTestId('create-view-button');
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findVisibilityGlRadioButtons = () => findVisibilityInputs().findAllComponents(GlFormRadio);
  const findWarningMessage = () => wrapper.findByTestId('subscription-limit-warning');
  const findWarningIcon = () => findWarningMessage().findComponent(GlIcon);
  const findLearnMoreLink = () => findWarningMessage().findComponent(GlLink);

  beforeEach(() => {
    mockToastShow.mockClear();
    saveSavedView.mockResolvedValue(successCreateResponse);
    createComponent();
  });

  it('correctly renders the modal, default title and the form', () => {
    expect(findForm().exists()).toBe(true);
    expect(findTitleInput().exists()).toBe(true);
    expect(findDescriptionInput().exists()).toBe(true);
    expect(findVisibilityInputs().exists()).toBe(true);
    expect(findModal().props('title')).toBe('New view');
  });

  it('correctly changes the passed title', () => {
    createComponent();
    expect(findModal().props('title')).toBe('New view');
  });

  it('autofocuses the title input when the modal is shown', async () => {
    findTitleInput().element.focus = jest.fn();

    findModal().vm.$emit('shown');
    await waitForPromises();

    expect(findTitleInput().element.focus).toHaveBeenCalled();
  });

  it('disables the submit button if invalid title is provided', async () => {
    findTitleInput().vm.$emit('input', '');

    findForm().vm.$emit('submit', {
      preventDefault: jest.fn(),
    });
    await waitForPromises();

    expect(findTitleInput().props().state).toBe(false);
    expect(findCreateButton().props('disabled')).toBe(true);
  });

  it('enables the submit button if title is entered after invalid title error', async () => {
    findTitleInput().vm.$emit('input', undefined);

    findForm().vm.$emit('submit', {
      preventDefault: jest.fn(),
    });
    await waitForPromises();

    expect(findTitleInput().props().state).toBe(false);
    expect(findCreateButton().props('disabled')).toBe(true);

    findTitleInput().vm.$emit('input', 'New view');
    await nextTick();

    expect(findTitleInput().props().state).toBe(true);
    expect(findCreateButton().props('disabled')).toBe(false);
  });

  it('creates new saved view and hides modal when submitting a form', async () => {
    findTitleInput().vm.$emit('input', 'view title');

    findForm().vm.$emit('submit', {
      preventDefault: jest.fn(),
    });

    await waitForPromises();

    expect(wrapper.emitted('hide')).toEqual([[false]]);
    expect(findModal().exists()).toBe(true);
  });

  describe('subscription limit warning', () => {
    describe('when showSubscriptionLimitWarning is false', () => {
      it('does not show the warning message', () => {
        createComponent({ props: { showSubscriptionLimitWarning: false } });

        expect(findWarningMessage().exists()).toBe(false);
      });
    });

    describe('when showSubscriptionLimitWarning is true', () => {
      beforeEach(() => {
        createComponent({ props: { showSubscriptionLimitWarning: true } });
      });

      it('shows the warning message with icon and link', () => {
        expect(findWarningMessage().exists()).toBe(true);
        expect(findWarningIcon().props('name')).toBe('warning');
        expect(findLearnMoreLink().exists()).toBe(true);
      });

      it('contains the correct warning text', () => {
        expect(findWarningMessage().text()).toContain(
          'You have reached the maximum number of views in your list.',
        );
        expect(findWarningMessage().text()).toContain(
          'If you add a view, the last view in your list will be removed.',
        );
      });
    });

    describe('when in edit mode', () => {
      it('does not show the warning even when showSubscriptionLimitWarning is true', () => {
        createComponent({
          props: { showSubscriptionLimitWarning: true },
          mockSavedView: existingSavedView,
        });

        expect(findWarningMessage().exists()).toBe(false);
      });
    });
  });

  describe('createSavedViewMutation', () => {
    const filters = { filters: { search: 'text' } };
    const displaySettings = { hiddenMetadataKeys: ['assignee'] };
    const sortKey = UPDATED_DESC;

    it.each`
      scenario                   | props                                    | expectedSortKey | expectedFilters   | expectedDisplaySettings
      ${'with no config'}        | ${{}}                                    | ${CREATED_DESC} | ${{}}             | ${{}}
      ${'with sort'}             | ${{ sortKey }}                           | ${UPDATED_DESC} | ${{}}             | ${{}}
      ${'with filters'}          | ${{ filters }}                           | ${CREATED_DESC} | ${{ ...filters }} | ${{}}
      ${'with display settings'} | ${{ displaySettings }}                   | ${CREATED_DESC} | ${{}}             | ${{ ...displaySettings }}
      ${'with all config'}       | ${{ filters, displaySettings, sortKey }} | ${UPDATED_DESC} | ${{ ...filters }} | ${{ ...displaySettings }}
    `(
      'successfully creates a saved view $scenario and shows a toast message',
      async ({ props, expectedSortKey, expectedFilters, expectedDisplaySettings }) => {
        createComponent({ props });

        findTitleInput().vm.$emit('input', 'Test View');
        findDescriptionInput().vm.$emit('input', 'Test Description');

        findForm().vm.$emit('submit', {
          preventDefault: jest.fn(),
        });

        await waitForPromises();

        expect(saveSavedView).toHaveBeenCalledWith({
          apolloClient: undefined,
          id: undefined,
          isEdit: false,
          isForm: true,
          namespacePath: 'test-project-path',
          name: 'Test View',
          description: 'Test Description',
          isPrivate: true,
          filters: expectedFilters,
          displaySettings: expectedDisplaySettings,
          sort: expectedSortKey,
          mutationKey: 'workItemSavedViewCreate',
          subscribed: undefined,
          userPermissions: undefined,
          subscribedSavedViewLimit: 5,
        });

        expect(mockToastShow).toHaveBeenCalledWith('New view created.');
        expect(wrapper.emitted('hide')).toEqual([[false]]);
      },
    );

    it.each`
      scenario                            | mockSetup                                                                                              | expectedError
      ${'with errors in response'}        | ${{ data: { workItemSavedViewCreate: { errors: ['Failed to create saved view'], savedView: null } } }} | ${'Something went wrong while creating the view'}
      ${'when mutation throws exception'} | ${new Error('Network error')}                                                                          | ${'Something went wrong while creating the view'}
    `('shows an error message $scenario', async ({ mockSetup, expectedError }) => {
      if (mockSetup instanceof Error) {
        saveSavedView.mockRejectedValue(mockSetup);
      } else {
        saveSavedView.mockResolvedValue(mockSetup);
      }

      createComponent();

      findTitleInput().vm.$emit('input', 'Test View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(saveSavedView).toHaveBeenCalled();
      expect(findAlert().text()).toBe(expectedError);
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });

  describe('updateSavedViewMutation', () => {
    it('renders the modal with edit title when savedView has an id', () => {
      createComponent({ mockSavedView: existingSavedView });

      expect(findModal().props('title')).toBe('Edit view');
    });

    it('renders the submit button with "Save" label in edit mode', () => {
      createComponent({ mockSavedView: existingSavedView });

      expect(findCreateButton().text()).toBe('Save');
    });

    it('pre-populates the form with existing saved view data', () => {
      createComponent({ mockSavedView: existingSavedView });

      expect(findTitleInput().attributes('value')).toBe('Existing View');
      expect(findDescriptionInput().attributes('value')).toBe('Existing Description');
    });

    it('sets visibility to shared when savedView.isPrivate is false', () => {
      createComponent({ mockSavedView: existingSavedView });

      expect(findVisibilityGlRadioButtons().at(1).props().checked).toBe(
        SAVED_VIEW_VISIBILITY.SHARED,
      );
    });

    // Note: The form is not supposed to update the filters, display settings and sort key
    it('successfully updates a saved view and shows a toast message', async () => {
      saveSavedView.mockResolvedValue(successUpdateResponse);

      createComponent({ mockSavedView: existingSavedView });

      findTitleInput().vm.$emit('input', 'Updated View');
      findDescriptionInput().vm.$emit('input', 'Updated Description');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(saveSavedView).toHaveBeenCalledWith({
        apolloClient: undefined,
        id: 'gid://gitlab/WorkItems::SavedView/123',
        name: 'Updated View',
        description: 'Updated Description',
        isPrivate: false,
        filters: {},
        displaySettings: {},
        sort: CREATED_DESC,
        isEdit: true,
        isForm: true,
        mutationKey: 'workItemSavedViewUpdate',
        namespacePath: 'test-project-path',
        subscribed: true,
        subscribedSavedViewLimit: 5,
        userPermissions: {
          deleteSavedView: true,
          updateSavedView: true,
        },
      });

      expect(mockToastShow).toHaveBeenCalledWith('View has been saved.');
      expect(wrapper.emitted('hide')).toEqual([[false]]);
    });

    it('shows an error message when update mutation fails with errors in response', async () => {
      saveSavedView.mockResolvedValue({
        data: {
          workItemSavedViewCreate: {
            errors: ['Failed to create saved view'],
            savedView: null,
          },
        },
      });

      createComponent({
        mockSavedView: existingSavedView,
      });

      findTitleInput().vm.$emit('input', 'Updated View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(saveSavedView).toHaveBeenCalled();
      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });

    it('shows an error message when update mutation throws an exception', async () => {
      saveSavedView.mockRejectedValue(new Error('Network error'));

      createComponent({
        mockSavedView: existingSavedView,
      });

      findTitleInput().vm.$emit('input', 'Updated View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(saveSavedView).toHaveBeenCalled();
      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });
});
