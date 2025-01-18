import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import VueDraggable from 'vuedraggable';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { isLoggedIn } from '~/lib/utils/common_utils';

import CrudComponent from '~/vue_shared/components/crud_component.vue';
import DesignDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import getWorkItemDesignListQuery from '~/work_items/components/design_management/graphql/design_collection.query.graphql';
import moveDesignMutation from '~/work_items/components/design_management/graphql/move_design.mutation.graphql';
import archiveDesignMutation from '~/work_items/components/design_management/graphql/archive_design.mutation.graphql';
import DesignItem from '~/work_items/components/design_management/design_item.vue';
import DesignWidget from '~/work_items/components/design_management/design_management_widget.vue';
import { createMockDirective } from 'helpers/vue_mock_directive';
import {
  designArchiveError,
  ALERT_VARIANTS,
  VALID_DESIGN_FILE_MIMETYPE,
  MOVE_DESIGN_ERROR,
} from '~/work_items/components/design_management/constants';

import {
  designCollectionResponse,
  mockDesign,
  mockDesign2,
  mockArchiveDesignMutationResponse,
  mockMoveDesignMutationResponse,
  mockMoveDesignMutationErrorResponse,
  allDesignsArchivedResponse,
} from './mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/alert');
Vue.use(VueApollo);

const PREVIOUS_VERSION_ID = 2;
const ALL_DESIGNS_ARCHIVED_TEXT = 'All designs have been archived.';

const designRouteFactory = (versionId) => ({
  path: `?version=${versionId}`,
  query: {
    version: `${versionId}`,
  },
});

const MOCK_ROUTE = {
  path: '/',
  query: {},
};

describe('DesignWidget', () => {
  let wrapper;
  const workItemId = 'gid://gitlab/WorkItem/1';

  const oneDesignQueryHandler = jest.fn().mockResolvedValue(designCollectionResponse());
  const twoDesignsQueryHandler = jest
    .fn()
    .mockResolvedValue(designCollectionResponse([mockDesign, mockDesign2]));
  const archiveDesignSuccessMutationHandler = jest
    .fn()
    .mockResolvedValue(mockArchiveDesignMutationResponse);
  const archiveDesignMutationError = jest.fn().mockRejectedValue(new Error('Mutation failed'));
  const allDesignsArchivedQueryHandler = jest.fn().mockResolvedValue(allDesignsArchivedResponse());
  const moveDesignSuccessMutationHandler = jest
    .fn()
    .mockResolvedValue(mockMoveDesignMutationResponse);
  const moveDesignMutationError = jest.fn().mockResolvedValue(mockMoveDesignMutationErrorResponse);

  const findWidgetWrapper = () => wrapper.findComponent(CrudComponent);
  const findDesignDropzoneComponent = () => wrapper.findComponent(DesignDropzone);
  const findAllDesignItems = () => wrapper.findAllComponents(DesignItem);
  const findArchiveButton = () => wrapper.findByTestId('archive-button');
  const findSelectAllButton = () => wrapper.findByTestId('select-all-designs-button');
  const findDesignCheckboxes = () => wrapper.findAllByTestId('design-checkbox');
  const findVueDraggable = () => wrapper.findComponent(VueDraggable);
  const findAlert = () => wrapper.findComponent(GlAlert);

  async function moveDesigns() {
    await waitForPromises();

    findVueDraggable().vm.$emit('input', [mockDesign2, mockDesign]);
    findVueDraggable().vm.$emit('change', {
      moved: {
        newIndex: 0,
        element: mockDesign2,
      },
    });
  }

  function createComponent({
    designCollectionQueryHandler = oneDesignQueryHandler,
    archiveDesignMutationHandler = archiveDesignSuccessMutationHandler,
    moveDesignMutationHandler = moveDesignSuccessMutationHandler,
    routeArg = MOCK_ROUTE,
    uploadError = null,
    uploadErrorVariant = ALERT_VARIANTS.danger,
    canReorderDesign = true,
  } = {}) {
    wrapper = shallowMountExtended(DesignWidget, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: createMockApollo([
        [getWorkItemDesignListQuery, designCollectionQueryHandler],
        [archiveDesignMutation, archiveDesignMutationHandler],
        [moveDesignMutation, moveDesignMutationHandler],
      ]),
      propsData: {
        workItemId,
        uploadError,
        uploadErrorVariant,
        canReorderDesign,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      mocks: {
        $route: routeArg,
      },
      provide: {
        fullPath: 'gitlab-org/gitlab-shell',
      },
      stubs: {
        RouterView: true,
        VueDraggable,
      },
    });
  }

  describe('when work item has designs', () => {
    beforeEach(() => {
      isLoggedIn.mockReturnValue(true);
      createComponent();
      return waitForPromises();
    });

    it('renders widget header with add design button', () => {
      expect(wrapper.findByTestId('add-design').exists()).toBe(true);
      expect(wrapper.find('input[type="file"]').exists()).toBe(true);
    });

    it('renders design-dropzone component', () => {
      const designDropzone = findDesignDropzoneComponent();
      expect(designDropzone.exists()).toBe(true);
      expect(designDropzone.props()).toMatchObject({
        showUploadDesignOverlay: true,
        validateDesignUploadOnDragover: true,
        acceptDesignFormats: VALID_DESIGN_FILE_MIMETYPE.mimetype,
        uploadDesignOverlayText: 'Drop your images to start the upload.',
      });
    });

    it('calls design collection query without version by default', () => {
      expect(oneDesignQueryHandler).toHaveBeenCalledWith({
        id: workItemId,
        atVersion: null,
      });
    });

    it('renders widget wrapper', () => {
      expect(findWidgetWrapper().exists()).toBe(true);
    });

    it('renders VueDraggable component', () => {
      expect(findVueDraggable().exists()).toBe(true);
      expect(findVueDraggable().vm.$attrs.disabled).toBe(false);
    });

    it('renders VueDraggable component with dragging disabled when canReorderDesign prop is false', async () => {
      await createComponent({ canReorderDesign: false });
      await waitForPromises();

      expect(findVueDraggable().vm.$attrs.disabled).toBe(true);
    });

    it('calls moveDesignMutation with correct parameters and reorders designs', async () => {
      createComponent({ designCollectionQueryHandler: twoDesignsQueryHandler });
      await moveDesigns();

      expect(moveDesignSuccessMutationHandler).toHaveBeenCalled();

      await waitForPromises();

      expect(findAllDesignItems().at(0).props('id')).toBe(mockDesign2.id);
    });

    it('throws error if reordering of designs mutation fails', async () => {
      createComponent({
        designCollectionQueryHandler: twoDesignsQueryHandler,
        moveDesignMutationHandler: moveDesignMutationError,
      });

      await moveDesigns();
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: MOVE_DESIGN_ERROR });
    });

    it('renders Select All and Archive Selected buttons', () => {
      expect(findArchiveButton().exists()).toBe(true);
      expect(findSelectAllButton().exists()).toBe(true);
    });

    it('does not render Select All and Archive Selected buttons if the current version is not the latest', async () => {
      createComponent({ routeArg: designRouteFactory(PREVIOUS_VERSION_ID) });

      await waitForPromises();

      expect(findArchiveButton().exists()).toBe(false);
      expect(findSelectAllButton().exists()).toBe(false);
    });

    it('adds all designs to selected designs when Select All button is clicked', async () => {
      findSelectAllButton().vm.$emit('click');

      await nextTick();
      expect(findArchiveButton().props().hasSelectedDesigns).toBe(true);
      expect(findSelectAllButton().text()).toBe('Deselect all');
    });

    it('archives a design', async () => {
      findDesignCheckboxes().at(0).trigger('click');

      await nextTick();

      findArchiveButton().vm.$emit('archive-selected-designs');
      await waitForPromises();

      expect(archiveDesignSuccessMutationHandler).toHaveBeenCalled();
    });

    it('throws error if archive a design mutation fails', async () => {
      createComponent({ archiveDesignMutationHandler: archiveDesignMutationError });
      await waitForPromises();

      findArchiveButton().vm.$emit('archive-selected-designs');
      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(designArchiveError(2));
    });

    it('renders error alert based on provided uploadErrorVariant prop', async () => {
      const uploadError = 'Design with same name already present, upload skipped.';
      createComponent({ uploadError, uploadErrorVariant: ALERT_VARIANTS.info });
      await waitForPromises();

      const alertComponent = wrapper.findComponent(GlAlert);
      expect(alertComponent.exists()).toBe(true);
      expect(alertComponent.props('variant')).toBe(ALERT_VARIANTS.info);
      expect(alertComponent.text()).toBe(uploadError);
    });
  });

  it('calls design collection query with version passed in route', async () => {
    createComponent({ routeArg: designRouteFactory(PREVIOUS_VERSION_ID) });

    await waitForPromises();

    expect(oneDesignQueryHandler).toHaveBeenCalledWith({
      id: workItemId,
      atVersion: `gid://gitlab/DesignManagement::Version/${PREVIOUS_VERSION_ID}`,
    });
  });

  it.each`
    length | queryHandler
    ${1}   | ${oneDesignQueryHandler}
    ${2}   | ${twoDesignsQueryHandler}
  `('renders $length designs and checkboxes', async ({ length, queryHandler }) => {
    createComponent({ designCollectionQueryHandler: queryHandler });
    await waitForPromises();

    expect(queryHandler).toHaveBeenCalled();
    expect(findAllDesignItems().length).toBe(length);
    expect(findDesignCheckboxes().length).toBe(length);
  });

  it('renders text if all designs are archived', async () => {
    createComponent({ designCollectionQueryHandler: allDesignsArchivedQueryHandler });
    await waitForPromises();

    expect(findAllDesignItems().length).toBe(0);
    expect(wrapper.text()).toContain(ALL_DESIGNS_ARCHIVED_TEXT);
  });

  it('dismisses error passed as prop', async () => {
    createComponent({ uploadError: 'Error uploading a new design. Please try again.' });
    await waitForPromises();

    expect(findAlert().exists()).toBe(true);
    findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismissError')).toHaveLength(1);
  });

  describe('when user is not logged in', () => {
    beforeEach(() => {
      isLoggedIn.mockReturnValue(false);
      createComponent();
    });

    it('does not render VueDraggable component if user is logged out', () => {
      expect(findVueDraggable().exists()).toBe(false);
    });
  });
});
