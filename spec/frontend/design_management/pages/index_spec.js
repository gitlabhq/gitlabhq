import { GlEmptyState } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo, { ApolloMutation } from 'vue-apollo';
import VueRouter from 'vue-router';
import VueDraggable from 'vuedraggable';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import permissionsQuery from 'shared_queries/design_management/design_permissions.query.graphql';
import getDesignListQuery from 'shared_queries/design_management/get_design_list.query.graphql';
import DeleteButton from '~/design_management/components/delete_button.vue';
import DesignDestroyer from '~/design_management/components/design_destroyer.vue';
import Design from '~/design_management/components/list/item.vue';
import moveDesignMutation from '~/design_management/graphql/mutations/move_design.mutation.graphql';
import uploadDesignMutation from '~/design_management/graphql/mutations/upload_design.mutation.graphql';
import Index from '~/design_management/pages/index.vue';
import createRouter from '~/design_management/router';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';
import * as utils from '~/design_management/utils/design_management_utils';
import {
  EXISTING_DESIGN_DROP_MANY_FILES_MESSAGE,
  EXISTING_DESIGN_DROP_INVALID_FILENAME_MESSAGE,
} from '~/design_management/utils/error_messages';
import {
  DESIGN_TRACKING_PAGE_NAME,
  DESIGN_SNOWPLOW_EVENT_TYPES,
} from '~/design_management/utils/tracking';
import createFlash from '~/flash';
import DesignDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import {
  designListQueryResponse,
  designUploadMutationCreatedResponse,
  designUploadMutationUpdatedResponse,
  permissionsQueryResponse,
  moveDesignMutationResponse,
  reorderedDesigns,
  moveDesignMutationResponseWithErrors,
} from '../mock_data/apollo_mock';

jest.mock('~/flash.js');
const mockPageEl = {
  classList: {
    remove: jest.fn(),
  },
};
jest.spyOn(utils, 'getPageLayoutElement').mockReturnValue(mockPageEl);

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

const localVue = createLocalVue();
const router = createRouter();
localVue.use(VueRouter);

const mockDesigns = [
  {
    id: 'design-1',
    image: 'design-1-image',
    filename: 'design-1-name',
    event: 'NONE',
    notesCount: 0,
  },
  {
    id: 'design-2',
    image: 'design-2-image',
    filename: 'design-2-name',
    event: 'NONE',
    notesCount: 1,
  },
  {
    id: 'design-3',
    image: 'design-3-image',
    filename: 'design-3-name',
    event: 'NONE',
    notesCount: 0,
  },
];

const mockVersion = {
  id: 'gid://gitlab/DesignManagement::Version/1',
};

const designToMove = {
  __typename: 'Design',
  id: '2',
  event: 'NONE',
  filename: 'fox_2.jpg',
  notesCount: 2,
  image: 'image-2',
  imageV432x230: 'image-2',
};

describe('Design management index page', () => {
  let mutate;
  let wrapper;
  let fakeApollo;
  let moveDesignHandler;

  const findDesignCheckboxes = () => wrapper.findAll('.design-checkbox');
  const findSelectAllButton = () => wrapper.find('[data-testid="select-all-designs-button"');
  const findToolbar = () => wrapper.find('.qa-selector-toolbar');
  const findDesignCollectionIsCopying = () =>
    wrapper.find('[data-testid="design-collection-is-copying"');
  const findDeleteButton = () => wrapper.find(DeleteButton);
  const findDropzone = () => wrapper.findAll(DesignDropzone).at(0);
  const dropzoneClasses = () => findDropzone().classes();
  const findDropzoneWrapper = () => wrapper.find('[data-testid="design-dropzone-wrapper"]');
  const findFirstDropzoneWithDesign = () => wrapper.findAll(DesignDropzone).at(1);
  const findDesignsWrapper = () => wrapper.find('[data-testid="designs-root"]');
  const findDesigns = () => wrapper.findAll(Design);
  const draggableAttributes = () => wrapper.find(VueDraggable).vm.$attrs;
  const findDesignUploadButton = () => wrapper.find('[data-testid="design-upload-button"]');
  const findDesignToolbarWrapper = () => wrapper.find('[data-testid="design-toolbar-wrapper"]');

  async function moveDesigns(localWrapper) {
    await jest.runOnlyPendingTimers();
    await nextTick();

    localWrapper.find(VueDraggable).vm.$emit('input', reorderedDesigns);
    localWrapper.find(VueDraggable).vm.$emit('change', {
      moved: {
        newIndex: 0,
        element: designToMove,
      },
    });
  }

  function createComponent({
    loading = false,
    allVersions = [],
    designCollection = { designs: mockDesigns, copyState: 'READY' },
    createDesign = true,
    stubs = {},
    mockMutate = jest.fn().mockResolvedValue(),
  } = {}) {
    mutate = mockMutate;
    const $apollo = {
      queries: {
        designCollection: {
          loading,
        },
        permissions: {
          loading,
        },
      },
      mutate,
    };

    wrapper = shallowMount(Index, {
      data() {
        return {
          allVersions,
          designCollection,
          permissions: {
            createDesign,
          },
        };
      },
      mocks: { $apollo },
      localVue,
      router,
      stubs: { DesignDestroyer, ApolloMutation, VueDraggable, ...stubs },
      attachTo: document.body,
      provide: {
        projectPath: 'project-path',
        issueIid: '1',
      },
    });
  }

  function createComponentWithApollo({
    moveHandler = jest.fn().mockResolvedValue(moveDesignMutationResponse),
  }) {
    localVue.use(VueApollo);
    moveDesignHandler = moveHandler;

    const requestHandlers = [
      [getDesignListQuery, jest.fn().mockResolvedValue(designListQueryResponse)],
      [permissionsQuery, jest.fn().mockResolvedValue(permissionsQueryResponse)],
      [moveDesignMutation, moveDesignHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers);
    wrapper = shallowMount(Index, {
      localVue,
      apolloProvider: fakeApollo,
      router,
      stubs: { VueDraggable },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('designs', () => {
    it('renders loading icon', () => {
      createComponent({ loading: true });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders error', async () => {
      createComponent();

      wrapper.setData({ error: true });

      await nextTick();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders a toolbar with buttons when there are designs', () => {
      createComponent({ allVersions: [mockVersion] });

      expect(findToolbar().exists()).toBe(true);
    });

    it('renders designs list and header with upload button', () => {
      createComponent({ allVersions: [mockVersion] });

      expect(findDesignsWrapper().exists()).toBe(true);
      expect(findDesigns().length).toBe(3);
      expect(findDesignToolbarWrapper().exists()).toBe(true);
      expect(findDesignUploadButton().exists()).toBe(true);
    });

    it('does not render toolbar when there is no permission', () => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion], createDesign: false });

      expect(findDesignToolbarWrapper().exists()).toBe(false);
      expect(findDesignUploadButton().exists()).toBe(false);
    });

    it('has correct classes applied to design dropzone', () => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });
      expect(dropzoneClasses()).toContain('design-list-item');
      expect(dropzoneClasses()).toContain('design-list-item-new');
    });

    it('has correct classes applied to dropzone wrapper', () => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });
      expect(findDropzoneWrapper().classes()).toEqual([
        'gl-flex-direction-column',
        'col-md-6',
        'col-lg-3',
        'gl-mb-3',
      ]);
    });
  });

  describe('when has no designs', () => {
    beforeEach(() => {
      createComponent({ designCollection: { designs: [], copyState: 'READY' } });
    });

    it('renders design dropzone', async () => {
      await nextTick();
      expect(findDropzone().exists()).toBe(true);
    });

    it('has correct classes applied to design dropzone', () => {
      expect(dropzoneClasses()).not.toContain('design-list-item');
      expect(dropzoneClasses()).not.toContain('design-list-item-new');
    });

    it('has correct classes applied to dropzone wrapper', () => {
      expect(findDropzoneWrapper().classes()).toEqual(['col-12']);
    });

    it('does not render a toolbar with buttons', async () => {
      await nextTick();
      expect(findToolbar().exists()).toBe(false);
    });
  });

  describe('handling design collection copy state', () => {
    it.each`
      copyState        | isRendered | description
      ${'IN_PROGRESS'} | ${true}    | ${'renders'}
      ${'READY'}       | ${false}   | ${'does not render'}
      ${'ERROR'}       | ${false}   | ${'does not render'}
    `(
      '$description the copying message if design collection copyState is $copyState',
      ({ copyState, isRendered }) => {
        createComponent({ designCollection: { designs: [], copyState } });
        expect(findDesignCollectionIsCopying().exists()).toBe(isRendered);
      },
    );
  });

  describe('uploading designs', () => {
    it('calls mutation on upload', async () => {
      createComponent({ stubs: { GlEmptyState } });

      const mutationVariables = {
        update: expect.anything(),
        context: {
          hasUpload: true,
        },
        mutation: uploadDesignMutation,
        variables: {
          files: [{ name: 'test' }],
          projectPath: 'project-path',
          iid: '1',
        },
        optimisticResponse: {
          __typename: 'Mutation',
          designManagementUpload: {
            __typename: 'DesignManagementUploadPayload',
            designs: [
              {
                __typename: 'Design',
                id: expect.anything(),
                currentUserTodos: {
                  __typename: 'TodoConnection',
                  nodes: [],
                },
                image: '',
                imageV432x230: '',
                filename: 'test',
                fullPath: '',
                event: 'NONE',
                notesCount: 0,
                diffRefs: {
                  __typename: 'DiffRefs',
                  baseSha: '',
                  startSha: '',
                  headSha: '',
                },
                discussions: {
                  __typename: 'DesignDiscussion',
                  nodes: [],
                },
                versions: {
                  __typename: 'DesignVersionConnection',
                  nodes: {
                    __typename: 'DesignVersion',
                    id: expect.anything(),
                    sha: expect.anything(),
                  },
                },
              },
            ],
            skippedDesigns: [],
            errors: [],
          },
        },
      };

      await nextTick();
      findDropzone().vm.$emit('change', [{ name: 'test' }]);
      expect(mutate).toHaveBeenCalledWith(mutationVariables);
      expect(wrapper.vm.filesToBeSaved).toEqual([{ name: 'test' }]);
      expect(wrapper.vm.isSaving).toBeTruthy();
      expect(dropzoneClasses()).toContain('design-list-item');
      expect(dropzoneClasses()).toContain('design-list-item-new');
    });

    it('sets isSaving', async () => {
      createComponent();

      const uploadDesign = wrapper.vm.onUploadDesign([
        {
          name: 'test',
        },
      ]);

      expect(wrapper.vm.isSaving).toBe(true);

      await uploadDesign;
      expect(wrapper.vm.isSaving).toBe(false);
    });

    it('updates state appropriately after upload complete', async () => {
      createComponent({ stubs: { GlEmptyState } });
      wrapper.setData({ filesToBeSaved: [{ name: 'test' }] });

      wrapper.vm.onUploadDesignDone(designUploadMutationCreatedResponse);
      await nextTick();

      expect(wrapper.vm.filesToBeSaved).toEqual([]);
      expect(wrapper.vm.isSaving).toBeFalsy();
      expect(wrapper.vm.isLatestVersion).toBe(true);
    });

    it('updates state appropriately after upload error', async () => {
      createComponent({ stubs: { GlEmptyState } });
      wrapper.setData({ filesToBeSaved: [{ name: 'test' }] });

      wrapper.vm.onUploadDesignError();
      await nextTick();
      expect(wrapper.vm.filesToBeSaved).toEqual([]);
      expect(wrapper.vm.isSaving).toBeFalsy();
      expect(createFlash).toHaveBeenCalled();
    });

    it('does not call mutation if createDesign is false', () => {
      createComponent({ createDesign: false });

      wrapper.vm.onUploadDesign([]);

      expect(mutate).not.toHaveBeenCalled();
    });

    describe('upload count limit', () => {
      const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

      it('does not warn when the max files are uploaded', () => {
        createComponent();

        wrapper.vm.onUploadDesign(new Array(MAXIMUM_FILE_UPLOAD_LIMIT).fill(mockDesigns[0]));

        expect(createFlash).not.toHaveBeenCalled();
      });

      it('warns when too many files are uploaded', () => {
        createComponent();

        wrapper.vm.onUploadDesign(new Array(MAXIMUM_FILE_UPLOAD_LIMIT + 1).fill(mockDesigns[0]));

        expect(createFlash).toHaveBeenCalled();
      });
    });

    it('flashes warning if designs are skipped', async () => {
      createComponent({
        mockMutate: () =>
          Promise.resolve({
            data: { designManagementUpload: { skippedDesigns: [{ filename: 'test.jpg' }] } },
          }),
      });

      const uploadDesign = wrapper.vm.onUploadDesign([
        {
          name: 'test',
        },
      ]);

      await uploadDesign;
      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith({
        message: 'Upload skipped. test.jpg did not change.',
        types: 'warning',
      });
    });

    describe('dragging onto an existing design', () => {
      let mockMutate;
      beforeEach(() => {
        mockMutate = jest.fn().mockResolvedValue();
        createComponent({ designs: mockDesigns, allVersions: [mockVersion], mockMutate });
      });

      it('uploads designs with valid upload', () => {
        const mockUploadPayload = [
          {
            name: mockDesigns[0].filename,
          },
        ];

        const designDropzone = findFirstDropzoneWithDesign();
        designDropzone.vm.$emit('change', mockUploadPayload);

        const [{ mutation, variables }] = mockMutate.mock.calls[0];
        expect(mutation).toBe(uploadDesignMutation);
        expect(variables).toStrictEqual({
          files: mockUploadPayload,
          iid: '1',
          projectPath: 'project-path',
        });
      });

      it.each`
        description             | eventPayload                              | message
        ${'> 1 file'}           | ${[{ name: 'test' }, { name: 'test-2' }]} | ${EXISTING_DESIGN_DROP_MANY_FILES_MESSAGE}
        ${'different filename'} | ${[{ name: 'wrong-name' }]}               | ${EXISTING_DESIGN_DROP_INVALID_FILENAME_MESSAGE}
      `('calls createFlash when upload has $description', ({ eventPayload, message }) => {
        const designDropzone = findFirstDropzoneWithDesign();
        designDropzone.vm.$emit('change', eventPayload);

        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(createFlash).toHaveBeenCalledWith({ message });
      });
    });

    describe('tracking', () => {
      let trackingSpy;

      beforeEach(() => {
        trackingSpy = mockTracking('_category_', undefined, jest.spyOn);

        createComponent({ stubs: { GlEmptyState } });
      });

      afterEach(() => {
        unmockTracking();
      });

      it('tracks design creation', () => {
        wrapper.vm.onUploadDesignDone(designUploadMutationCreatedResponse);

        expect(trackingSpy).toHaveBeenCalledTimes(1);
        expect(trackingSpy).toHaveBeenCalledWith(
          DESIGN_TRACKING_PAGE_NAME,
          DESIGN_SNOWPLOW_EVENT_TYPES.CREATE_DESIGN,
        );
      });

      it('tracks design modification', () => {
        wrapper.vm.onUploadDesignDone(designUploadMutationUpdatedResponse);

        expect(trackingSpy).toHaveBeenCalledTimes(1);
        expect(trackingSpy).toHaveBeenCalledWith(
          DESIGN_TRACKING_PAGE_NAME,
          DESIGN_SNOWPLOW_EVENT_TYPES.UPDATE_DESIGN,
        );
      });
    });
  });

  describe('on latest version when has designs', () => {
    beforeEach(() => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });
    });

    it('renders design checkboxes', () => {
      expect(findDesignCheckboxes()).toHaveLength(mockDesigns.length);
    });

    it('renders toolbar buttons', () => {
      expect(findToolbar().exists()).toBe(true);
      expect(findToolbar().isVisible()).toBe(true);
    });

    it('adds two designs to selected designs when their checkboxes are checked', async () => {
      findDesignCheckboxes().at(0).trigger('click');

      await nextTick();
      findDesignCheckboxes().at(1).trigger('click');

      await nextTick();
      expect(findDeleteButton().exists()).toBe(true);
      expect(findSelectAllButton().text()).toBe('Deselect all');

      findDeleteButton().vm.$emit('delete-selected-designs');

      const [{ variables }] = mutate.mock.calls[0];
      expect(variables.filenames).toStrictEqual([mockDesigns[0].filename, mockDesigns[1].filename]);
    });

    it('adds all designs to selected designs when Select All button is clicked', async () => {
      findSelectAllButton().vm.$emit('click');

      await nextTick();
      expect(findDeleteButton().props().hasSelectedDesigns).toBe(true);
      expect(findSelectAllButton().text()).toBe('Deselect all');
      expect(wrapper.vm.selectedDesigns).toEqual(mockDesigns.map((design) => design.filename));
    });

    it('removes all designs from selected designs when at least one design was selected', async () => {
      findDesignCheckboxes().at(0).trigger('click');
      await nextTick();

      findSelectAllButton().vm.$emit('click');
      await nextTick();

      expect(findDeleteButton().props().hasSelectedDesigns).toBe(false);
      expect(findSelectAllButton().text()).toBe('Select all');
      expect(wrapper.vm.selectedDesigns).toEqual([]);
    });
  });

  it('on latest version when has no designs toolbar buttons are invisible', () => {
    createComponent({
      designCollection: { designs: [], copyState: 'READY' },
      allVersions: [mockVersion],
    });
    expect(findToolbar().isVisible()).toBe(false);
  });

  describe('on non-latest version', () => {
    beforeEach(() => {
      createComponent({ allVersions: [mockVersion] });
    });

    it('does not render design checkboxes', async () => {
      await router.replace({
        name: DESIGNS_ROUTE_NAME,
        query: {
          version: '2',
        },
      });
      expect(findDesignCheckboxes()).toHaveLength(0);
    });

    it('does not render Delete selected button', () => {
      expect(findDeleteButton().exists()).toBe(false);
    });

    it('does not render Select All button', () => {
      expect(findSelectAllButton().exists()).toBe(false);
    });
  });

  describe('pasting a design', () => {
    let event;
    let mockMutate;
    beforeEach(() => {
      mockMutate = jest.fn().mockResolvedValue({});
      createComponent({ designs: mockDesigns, allVersions: [mockVersion], mockMutate });

      event = new Event('paste');
      event.clipboardData = {
        files: [{ name: 'image.png', type: 'image/png' }],
        getData: () => 'test.png',
      };
    });

    it('does not upload designs if designs wrapper is not hovered', () => {
      document.dispatchEvent(event);

      expect(mockMutate).not.toHaveBeenCalled();
    });

    describe('when designs wrapper is hovered', () => {
      let realDateNow;
      const today = () => new Date('2020-12-25');
      beforeAll(() => {
        realDateNow = Date.now;
        global.Date.now = today;
      });

      afterAll(() => {
        global.Date.now = realDateNow;
      });

      beforeEach(() => {
        findDesignsWrapper().trigger('mouseenter');
      });

      it('uploads design with valid paste', () => {
        document.dispatchEvent(event);

        const [{ mutation, variables }] = mockMutate.mock.calls[0];
        expect(mutation).toBe(uploadDesignMutation);
        expect(variables).toStrictEqual({
          files: expect.any(Array),
          iid: '1',
          projectPath: 'project-path',
        });
        expect(variables.files).toEqual(event.clipboardData.files.map((f) => new File([f], '')));
      });

      it('renames a design if it has an image.png filename', () => {
        event.clipboardData.getData = () => 'image.png';
        document.dispatchEvent(event);

        const [{ mutation, variables }] = mockMutate.mock.calls[0];
        expect(mutation).toBe(uploadDesignMutation);
        expect(variables).toStrictEqual({
          files: expect.any(Array),
          iid: '1',
          projectPath: 'project-path',
        });
        expect(variables.files[0].name).toEqual(`design_${Date.now()}.png`);
      });

      it('does not call upload with invalid paste', () => {
        event.clipboardData = {
          items: [{ type: 'text/plain' }, { type: 'text' }],
          files: [],
        };

        document.dispatchEvent(event);

        expect(mockMutate).not.toHaveBeenCalled();
      });

      it('removes onPaste listener after mouseleave event', async () => {
        findDesignsWrapper().trigger('mouseleave');
        document.dispatchEvent(event);

        expect(mockMutate).not.toHaveBeenCalled();
      });
    });
  });

  describe('when navigating', () => {
    it('should trigger a scrollIntoView method if designs route is detected', async () => {
      router.replace({
        path: '/designs',
      });
      createComponent({ loading: true });

      await nextTick();
      expect(scrollIntoViewMock).toHaveBeenCalled();
    });
  });

  describe('with mocked Apollo client', () => {
    it('has a design with id 1 as a first one', async () => {
      createComponentWithApollo({});

      await jest.runOnlyPendingTimers();
      await nextTick();

      expect(findDesigns()).toHaveLength(3);
      expect(findDesigns().at(0).props('id')).toBe('1');
    });

    it('calls a mutation with correct parameters and reorders designs', async () => {
      createComponentWithApollo({});

      await moveDesigns(wrapper);

      expect(moveDesignHandler).toHaveBeenCalled();

      await nextTick();

      expect(findDesigns().at(0).props('id')).toBe('2');
    });

    it('prevents reordering when reorderDesigns mutation is in progress', async () => {
      createComponentWithApollo({});

      await moveDesigns(wrapper);

      expect(draggableAttributes().disabled).toBe(true);

      await jest.runOnlyPendingTimers(); // kick off the mocked GQL stuff (promises)
      await nextTick(); // kick off the DOM update
      await nextTick(); // kick off the DOM update for finally block

      expect(draggableAttributes().disabled).toBe(false);
    });

    it('displays flash if mutation had a recoverable error', async () => {
      createComponentWithApollo({
        moveHandler: jest.fn().mockResolvedValue(moveDesignMutationResponseWithErrors),
      });

      await moveDesigns(wrapper);

      await nextTick();

      expect(createFlash).toHaveBeenCalledWith({ message: 'Houston, we have a problem' });
    });

    it('displays flash if mutation had a non-recoverable error', async () => {
      createComponentWithApollo({
        moveHandler: jest.fn().mockRejectedValue('Error'),
      });

      await moveDesigns(wrapper);

      await nextTick(); // kick off the DOM update
      await jest.runOnlyPendingTimers(); // kick off the mocked GQL stuff (promises)
      await nextTick(); // kick off the DOM update for flash

      expect(createFlash).toHaveBeenCalledWith({
        message: 'Something went wrong when reordering designs. Please try again',
      });
    });
  });
});
