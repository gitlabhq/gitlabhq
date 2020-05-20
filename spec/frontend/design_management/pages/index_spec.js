import { createLocalVue, shallowMount } from '@vue/test-utils';
import { ApolloMutation } from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlEmptyState } from '@gitlab/ui';

import Index from '~/design_management/pages/index.vue';
import uploadDesignQuery from '~/design_management/graphql/mutations/uploadDesign.mutation.graphql';
import DesignDestroyer from '~/design_management/components/design_destroyer.vue';
import DesignDropzone from '~/design_management/components/upload/design_dropzone.vue';
import DeleteButton from '~/design_management/components/delete_button.vue';
import { DESIGNS_ROUTE_NAME } from '~/design_management/router/constants';
import {
  EXISTING_DESIGN_DROP_MANY_FILES_MESSAGE,
  EXISTING_DESIGN_DROP_INVALID_FILENAME_MESSAGE,
} from '~/design_management/utils/error_messages';
import createFlash from '~/flash';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter({
  routes: [
    {
      name: DESIGNS_ROUTE_NAME,
      path: '/designs',
      component: Index,
    },
  ],
});

jest.mock('~/flash.js');

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
  node: {
    id: 'gid://gitlab/DesignManagement::Version/1',
  },
};

describe('Design management index page', () => {
  let mutate;
  let wrapper;

  const findDesignCheckboxes = () => wrapper.findAll('.design-checkbox');
  const findSelectAllButton = () => wrapper.find('.js-select-all');
  const findToolbar = () => wrapper.find('.qa-selector-toolbar');
  const findDeleteButton = () => wrapper.find(DeleteButton);
  const findDropzone = () => wrapper.findAll(DesignDropzone).at(0);
  const findFirstDropzoneWithDesign = () => wrapper.findAll(DesignDropzone).at(1);

  function createComponent({
    loading = false,
    designs = [],
    allVersions = [],
    createDesign = true,
    stubs = {},
    mockMutate = jest.fn().mockResolvedValue(),
  } = {}) {
    mutate = mockMutate;
    const $apollo = {
      queries: {
        designs: {
          loading,
        },
        permissions: {
          loading,
        },
      },
      mutate,
    };

    wrapper = shallowMount(Index, {
      mocks: { $apollo },
      localVue,
      router,
      stubs: { DesignDestroyer, ApolloMutation, ...stubs },
      attachToDocument: true,
    });

    wrapper.setData({
      designs,
      allVersions,
      issueIid: '1',
      permissions: {
        createDesign,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('designs', () => {
    it('renders loading icon', () => {
      createComponent({ loading: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('renders error', () => {
      createComponent();

      wrapper.setData({ error: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('renders a toolbar with buttons when there are designs', () => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });

      return wrapper.vm.$nextTick().then(() => {
        expect(findToolbar().exists()).toBe(true);
      });
    });

    it('renders designs list and header with upload button', () => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('does not render toolbar when there is no permission', () => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion], createDesign: false });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });
  });

  describe('when has no designs', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders empty text', () =>
      wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      }));

    it('does not render a toolbar with buttons', () =>
      wrapper.vm.$nextTick().then(() => {
        expect(findToolbar().exists()).toBe(false);
      }));
  });

  describe('uploading designs', () => {
    it('calls mutation on upload', () => {
      createComponent({ stubs: { GlEmptyState } });

      const mutationVariables = {
        update: expect.anything(),
        context: {
          hasUpload: true,
        },
        mutation: uploadDesignQuery,
        variables: {
          files: [{ name: 'test' }],
          projectPath: '',
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
                  edges: {
                    __typename: 'DesignVersionEdge',
                    node: {
                      __typename: 'DesignVersion',
                      id: expect.anything(),
                      sha: expect.anything(),
                    },
                  },
                },
              },
            ],
            skippedDesigns: [],
            errors: [],
          },
        },
      };

      return wrapper.vm.$nextTick().then(() => {
        findDropzone().vm.$emit('change', [{ name: 'test' }]);
        expect(mutate).toHaveBeenCalledWith(mutationVariables);
        expect(wrapper.vm.filesToBeSaved).toEqual([{ name: 'test' }]);
        expect(wrapper.vm.isSaving).toBeTruthy();
      });
    });

    it('sets isSaving', () => {
      createComponent();

      const uploadDesign = wrapper.vm.onUploadDesign([
        {
          name: 'test',
        },
      ]);

      expect(wrapper.vm.isSaving).toBe(true);

      return uploadDesign.then(() => {
        expect(wrapper.vm.isSaving).toBe(false);
      });
    });

    it('updates state appropriately after upload complete', () => {
      createComponent({ stubs: { GlEmptyState } });
      wrapper.setData({ filesToBeSaved: [{ name: 'test' }] });

      wrapper.vm.onUploadDesignDone();
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.filesToBeSaved).toEqual([]);
        expect(wrapper.vm.isSaving).toBeFalsy();
        expect(wrapper.vm.isLatestVersion).toBe(true);
      });
    });

    it('updates state appropriately after upload error', () => {
      createComponent({ stubs: { GlEmptyState } });
      wrapper.setData({ filesToBeSaved: [{ name: 'test' }] });

      wrapper.vm.onUploadDesignError();
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.filesToBeSaved).toEqual([]);
        expect(wrapper.vm.isSaving).toBeFalsy();
        expect(createFlash).toHaveBeenCalled();

        createFlash.mockReset();
      });
    });

    it('does not call mutation if createDesign is false', () => {
      createComponent({ createDesign: false });

      wrapper.vm.onUploadDesign([]);

      expect(mutate).not.toHaveBeenCalled();
    });

    describe('upload count limit', () => {
      const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

      afterEach(() => {
        createFlash.mockReset();
      });

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

    it('flashes warning if designs are skipped', () => {
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

      return uploadDesign.then(() => {
        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(createFlash).toHaveBeenCalledWith(
          'Upload skipped. test.jpg did not change.',
          'warning',
        );
      });
    });

    describe('dragging onto an existing design', () => {
      beforeEach(() => {
        createComponent({ designs: mockDesigns, allVersions: [mockVersion] });
      });

      it('calls onUploadDesign with valid upload', () => {
        wrapper.setMethods({
          onUploadDesign: jest.fn(),
        });

        const mockUploadPayload = [
          {
            name: mockDesigns[0].filename,
          },
        ];

        const designDropzone = findFirstDropzoneWithDesign();
        designDropzone.vm.$emit('change', mockUploadPayload);

        expect(wrapper.vm.onUploadDesign).toHaveBeenCalledTimes(1);
        expect(wrapper.vm.onUploadDesign).toHaveBeenCalledWith(mockUploadPayload);
      });

      it.each`
        description             | eventPayload                              | message
        ${'> 1 file'}           | ${[{ name: 'test' }, { name: 'test-2' }]} | ${EXISTING_DESIGN_DROP_MANY_FILES_MESSAGE}
        ${'different filename'} | ${[{ name: 'wrong-name' }]}               | ${EXISTING_DESIGN_DROP_INVALID_FILENAME_MESSAGE}
      `('calls createFlash when upload has $description', ({ eventPayload, message }) => {
        const designDropzone = findFirstDropzoneWithDesign();
        designDropzone.vm.$emit('change', eventPayload);

        expect(createFlash).toHaveBeenCalledTimes(1);
        expect(createFlash).toHaveBeenCalledWith(message);
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
      expect(findToolbar().classes()).toContain('d-flex');
      expect(findToolbar().classes()).not.toContain('d-none');
    });

    it('adds two designs to selected designs when their checkboxes are checked', () => {
      findDesignCheckboxes()
        .at(0)
        .trigger('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          findDesignCheckboxes()
            .at(1)
            .trigger('click');

          return wrapper.vm.$nextTick();
        })
        .then(() => {
          expect(findDeleteButton().exists()).toBe(true);
          expect(findSelectAllButton().text()).toBe('Deselect all');
          findDeleteButton().vm.$emit('deleteSelectedDesigns');
          const [{ variables }] = mutate.mock.calls[0];
          expect(variables.filenames).toStrictEqual([
            mockDesigns[0].filename,
            mockDesigns[1].filename,
          ]);
        });
    });

    it('adds all designs to selected designs when Select All button is clicked', () => {
      findSelectAllButton().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(findDeleteButton().props().hasSelectedDesigns).toBe(true);
        expect(findSelectAllButton().text()).toBe('Deselect all');
        expect(wrapper.vm.selectedDesigns).toEqual(mockDesigns.map(design => design.filename));
      });
    });

    it('removes all designs from selected designs when at least one design was selected', () => {
      findDesignCheckboxes()
        .at(0)
        .trigger('click');

      return wrapper.vm
        .$nextTick()
        .then(() => {
          findSelectAllButton().vm.$emit('click');
        })
        .then(() => {
          expect(findDeleteButton().props().hasSelectedDesigns).toBe(false);
          expect(findSelectAllButton().text()).toBe('Select all');
          expect(wrapper.vm.selectedDesigns).toEqual([]);
        });
    });
  });

  it('on latest version when has no designs does not render toolbar buttons', () => {
    createComponent({ designs: [], allVersions: [mockVersion] });
    expect(findToolbar().exists()).toBe(false);
  });

  describe('on non-latest version', () => {
    beforeEach(() => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });

      router.replace({
        name: DESIGNS_ROUTE_NAME,
        query: {
          version: '2',
        },
      });
    });

    it('does not render design checkboxes', () => {
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
    beforeEach(() => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });

      wrapper.setMethods({
        onUploadDesign: jest.fn(),
      });

      event = new Event('paste');

      router.replace({
        name: DESIGNS_ROUTE_NAME,
        query: {
          version: '2',
        },
      });
    });

    it('calls onUploadDesign with valid paste', () => {
      event.clipboardData = {
        files: [{ name: 'image.png', type: 'image/png' }],
        getData: () => 'test.png',
      };

      document.dispatchEvent(event);

      expect(wrapper.vm.onUploadDesign).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.onUploadDesign).toHaveBeenCalledWith([
        new File([{ name: 'image.png' }], 'test.png'),
      ]);
    });

    it('renames a design if it has an image.png filename', () => {
      event.clipboardData = {
        files: [{ name: 'image.png', type: 'image/png' }],
        getData: () => 'image.png',
      };

      document.dispatchEvent(event);

      expect(wrapper.vm.onUploadDesign).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.onUploadDesign).toHaveBeenCalledWith([
        new File([{ name: 'image.png' }], `design_${Date.now()}.png`),
      ]);
    });

    it('does not call onUploadDesign with invalid paste', () => {
      event.clipboardData = {
        items: [{ type: 'text/plain' }, { type: 'text' }],
        files: [],
      };

      document.dispatchEvent(event);

      expect(wrapper.vm.onUploadDesign).not.toHaveBeenCalled();
    });
  });
});
