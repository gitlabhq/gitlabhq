import { GlDisclosureDropdown } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import LabelActions from '~/labels/components/label_actions.vue';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import updateLabelMutation from '~/labels/graphql/update_label.mutation.graphql';
import eventHub, {
  EVENT_OPEN_DELETE_LABEL_MODAL,
  EVENT_OPEN_PROMOTE_LABEL_MODAL,
  EVENT_ARCHIVE_LABEL_SUCCESS,
} from '~/labels/event_hub';

jest.mock('~/alert');

describe('LabelActions', () => {
  let wrapper;
  let mockApollo;

  Vue.use(VueApollo);

  const defaultPropsData = {
    labelId: '1',
    labelName: 'Label1',
    labelColor: '#ffffff',
    labelTextColor: '#000000',
    subjectName: 'My Test Project',
    editPath: '/admin/labels/1/edit',
    destroyPath: '/admin/labels/1',
    promotePath: '/my-test-group/my-test-project/-/labels/1/promote',
    groupName: 'My Test Group',
    archived: false,
  };

  const updateLabelMutationHandler = jest.fn();

  const mockToast = {
    show: jest.fn(),
  };

  const createComponent = (propsData = {}) => {
    mockApollo = createMockApollo([[updateLabelMutation, updateLabelMutationHandler]]);

    wrapper = mountExtended(LabelActions, {
      apolloProvider: mockApollo,
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      mocks: {
        $toast: mockToast,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const findDeleteAction = () => wrapper.findByTestId('delete-label-action');
  const findPromoteAction = () => wrapper.findByTestId('promote-label-action');
  const findToggleArchiveAction = () => wrapper.findByTestId('toggle-archive-label-action');

  beforeEach(() => {
    window.gon = { features: { labelsArchive: true } };
    updateLabelMutationHandler.mockReset();
    jest.clearAllMocks();
  });

  it('renders `GlDisclosureDropdown` with expected props', () => {
    createComponent();

    expect(findDropdown().props()).toMatchObject({
      icon: 'ellipsis_v',
      noCaret: true,
      placement: 'bottom-start',
      category: 'tertiary',
    });
  });

  it('renders dropdown actions', () => {
    createComponent();

    const items = findDropdown().props('items');
    expect(items).toHaveLength(4);

    const [editItem, promoteItem, archiveItem, deleteItem] = items;

    expect(editItem).toMatchObject({
      text: 'Edit',
      href: defaultPropsData.editPath,
    });

    expect(promoteItem).toMatchObject({
      text: 'Promote to group label',
      action: expect.any(Function),
    });

    expect(archiveItem).toMatchObject({
      text: 'Archive',
      action: expect.any(Function),
    });

    expect(deleteItem).toMatchObject({
      text: 'Delete',
      action: expect.any(Function),
      variant: 'danger',
    });
  });

  it('does not render archive when labels archive is not set', () => {
    window.gon = { features: {} };
    createComponent();

    const items = findDropdown().props('items');
    expect(items).toHaveLength(3);
    expect(items.map((item) => item.text)).not.toContain('Archive');
  });

  describe('Promote', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    it('emits open promote label modal', () => {
      createComponent();

      findPromoteAction().trigger('click');

      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_PROMOTE_LABEL_MODAL,
        expect.objectContaining({
          labelTitle: defaultPropsData.labelName,
          labelColor: defaultPropsData.labelColor,
          labelTextColor: defaultPropsData.labelTextColor,
          url: defaultPropsData.promotePath,
          groupName: defaultPropsData.groupName,
        }),
      );
    });

    it('does not render promote action', () => {
      createComponent({ promotePath: '' });

      const items = findDropdown().props('items');
      expect(items).toHaveLength(3);
      expect(items.map((item) => item.text)).not.toContain('Promote to group label');
    });
  });

  describe('DELETE', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    it('emits open delete label modal', () => {
      createComponent();

      findDeleteAction().trigger('click');

      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_DELETE_LABEL_MODAL,
        expect.objectContaining({
          labelId: defaultPropsData.labelId,
          labelName: defaultPropsData.labelName,
          destroyPath: defaultPropsData.destroyPath,
        }),
      );
    });
  });

  describe('Archive', () => {
    const mockedResolveValue = (archived) => {
      return {
        data: {
          labelUpdate: {
            label: { id: convertToGraphQLId('Label', '1'), archived },
            errors: [],
          },
        },
      };
    };
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit').mockImplementation();
    });

    describe('when labels archive feature is enabled', () => {
      describe('when label is not archived', () => {
        it('shows "Archive" action text', () => {
          createComponent({ archived: false });

          expect(findToggleArchiveAction().text()).toBe('Archive');
        });

        it('calls updateLabel mutation with archived: true when archive action is clicked', async () => {
          updateLabelMutationHandler.mockResolvedValue(mockedResolveValue(true));

          createComponent({ archived: false });

          findToggleArchiveAction().trigger('click');
          await waitForPromises();

          expect(updateLabelMutationHandler).toHaveBeenCalledWith({
            input: {
              id: convertToGraphQLId('Label', '1'),
              archived: true,
            },
          });

          expect(eventHub.$emit).toHaveBeenCalledWith(EVENT_ARCHIVE_LABEL_SUCCESS, '1');
          expect(mockToast.show).toHaveBeenCalledWith('Label archived.');
        });
      });

      describe('when label is archived', () => {
        it('shows "Unarchive" action text', () => {
          createComponent({ isArchived: true });

          expect(findToggleArchiveAction().text()).toBe('Unarchive');
        });

        it('calls updateLabel mutation with archived: false when unarchive action is clicked', async () => {
          updateLabelMutationHandler.mockResolvedValue(mockedResolveValue(false));

          createComponent({ isArchived: true });

          findToggleArchiveAction().trigger('click');
          await waitForPromises();

          expect(updateLabelMutationHandler).toHaveBeenCalledWith({
            input: {
              id: convertToGraphQLId('Label', '1'),
              archived: false,
            },
          });

          expect(eventHub.$emit).toHaveBeenCalledWith(EVENT_ARCHIVE_LABEL_SUCCESS, '1');
          expect(mockToast.show).toHaveBeenCalledWith('Label unarchived.');
        });
      });

      describe('when mutation fails', () => {
        it('shows error toast when mutation returns errors', async () => {
          updateLabelMutationHandler.mockResolvedValue({
            data: {
              labelUpdate: {
                label: null,
                errors: ['Something went wrong'],
              },
            },
          });

          createComponent({ archived: false });

          findToggleArchiveAction().trigger('click');
          await waitForPromises();

          expect(mockToast.show).toHaveBeenCalledWith(
            'An error occurred while archiving the label.',
          );
          expect(eventHub.$emit).not.toHaveBeenCalledWith(EVENT_ARCHIVE_LABEL_SUCCESS, '1');
        });

        it('shows error toast when mutation throws exception', async () => {
          updateLabelMutationHandler.mockRejectedValue(new Error('Network error'));

          createComponent({ archived: false });

          findToggleArchiveAction().trigger('click');
          await waitForPromises();

          expect(mockToast.show).toHaveBeenCalledWith(
            'An error occurred while archiving the label.',
          );

          expect(eventHub.$emit).not.toHaveBeenCalledWith(EVENT_ARCHIVE_LABEL_SUCCESS, '1');
        });
      });
    });

    describe('when labels archive feature is disabled', () => {
      beforeEach(() => {
        window.gon.features.labelsArchive = false;
      });

      it('does not render archive action', () => {
        createComponent();

        expect(findToggleArchiveAction().exists()).toBe(false);
      });
    });
  });
});
