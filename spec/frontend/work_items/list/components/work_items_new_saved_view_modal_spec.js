import { GlForm, GlModal, GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import WorkItemsNewSavedViewModal from '~/work_items/list/components/work_items_new_saved_view_modal.vue';
import createSavedViewMutation from '~/work_items/graphql/create_saved_view.mutation.graphql';
import { CREATED_DESC } from '~/work_items/list/constants';

import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

describe('WorkItemsNewSavedViewModal', () => {
  let wrapper;
  let mockApollo;

  const successMutationHandler = jest.fn().mockResolvedValue({
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
          userPermissions: {
            updateSavedView: true,
          },
        },
      },
    },
  });

  const mockToastShow = jest.fn();

  const createComponent = ({
    props,
    title = 'New view',
    mutationHandler = successMutationHandler,
  } = {}) => {
    mockApollo = createMockApollo([[createSavedViewMutation, mutationHandler]]);

    wrapper = shallowMountExtended(WorkItemsNewSavedViewModal, {
      apolloProvider: mockApollo,
      propsData: {
        show: true,
        title,
        fullPath: 'test-project-path',
        sortKey: CREATED_DESC,
        ...props,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
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

  beforeEach(() => {
    mockToastShow.mockClear();
    createComponent();
  });

  it('correctly renders the modal, default title and the form', () => {
    expect(findForm().exists()).toBe(true);
    expect(findTitleInput().exists()).toBe(true);
    expect(findDescriptionInput().exists()).toBe(true);
    expect(findVisibilityInputs().exists()).toBe(true);
    expect(findModal().props('title')).toBe('New view');
  });

  it('corecctly changes the passed title', () => {
    createComponent({ title: 'Save view' });
    expect(findModal().props('title')).toBe('Save view');
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

    expect(findCreateButton().props('disabled')).toBe(true);
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

  describe('createSavedViewMutation', () => {
    it('successfully creates a saved view and shows a toast message', async () => {
      createComponent({
        mutationHandlerOverride: successMutationHandler,
      });

      findTitleInput().vm.$emit('input', 'Test View');
      findDescriptionInput().vm.$emit('input', 'Test Description');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(successMutationHandler).toHaveBeenCalledWith({
        input: {
          namespacePath: 'test-project-path',
          name: 'Test View',
          description: 'Test Description',
          private: true,
          filters: {},
          displaySettings: {},
          sort: CREATED_DESC,
        },
      });

      expect(mockToastShow).toHaveBeenCalledWith('New view created.');
      expect(wrapper.emitted('hide')).toEqual([[false]]);
    });

    it('shows an error message when mutation fails with errors in response', async () => {
      const errorMutationHandler = jest.fn().mockResolvedValue({
        data: {
          workItemSavedViewCreate: {
            errors: ['Failed to create saved view'],
            savedView: null,
          },
        },
      });

      createComponent({
        mutationHandler: errorMutationHandler,
      });

      findTitleInput().vm.$emit('input', 'Test View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(errorMutationHandler).toHaveBeenCalled();

      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });

    it('shows an error message when mutation throws an exception', async () => {
      const exceptionMutationHandler = jest.fn().mockRejectedValue(new Error('Network error'));

      createComponent({
        mutationHandler: exceptionMutationHandler,
      });

      findTitleInput().vm.$emit('input', 'Test View');

      findForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
      });

      await waitForPromises();

      expect(exceptionMutationHandler).toHaveBeenCalled();
      expect(findAlert().text()).toBe('Something went wrong while saving the view');
      expect(mockToastShow).not.toHaveBeenCalled();
      expect(wrapper.emitted('hide')).toBeUndefined();
    });
  });
});
