import { GlFormGroup, GlSprintf, GlModal } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as ProjectsApi from '~/api/projects_api';
import ImportAProjectModal from '~/invite_members/components/import_a_project_modal.vue';
import ProjectSelect from '~/invite_members/components/project_select.vue';
import axios from '~/lib/utils/axios_utils';

let wrapper;
let mock;

const projectId = '1';
const projectName = 'test name';
const projectToBeImported = { id: '2' };
const $toast = {
  show: jest.fn(),
};

const createComponent = () => {
  wrapper = shallowMountExtended(ImportAProjectModal, {
    propsData: {
      projectId,
      projectName,
    },
    stubs: {
      GlModal: stubComponent(GlModal, {
        template:
          '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
      }),
      GlSprintf,
      GlFormGroup: stubComponent(GlFormGroup, {
        props: ['state', 'invalidFeedback'],
      }),
    },
    mocks: {
      $toast,
    },
  });
};

beforeEach(() => {
  gon.api_version = 'v4';
  mock = new MockAdapter(axios);
});

afterEach(() => {
  wrapper.destroy();
  mock.restore();
});

describe('ImportAProjectModal', () => {
  const findIntroText = () => wrapper.find({ ref: 'modalIntro' }).text();
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findImportButton = () => wrapper.findByTestId('import-button');
  const clickImportButton = () => findImportButton().vm.$emit('click');
  const clickCancelButton = () => findCancelButton().vm.$emit('click');
  const findFormGroup = () => wrapper.findByTestId('form-group');
  const formGroupInvalidFeedback = () => findFormGroup().props('invalidFeedback');
  const formGroupErrorState = () => findFormGroup().props('state');
  const findProjectSelect = () => wrapper.findComponent(ProjectSelect);

  describe('rendering the modal', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the modal with the correct title', () => {
      expect(wrapper.findComponent(GlModal).props('title')).toBe(
        'Import members from another project',
      );
    });

    it('renders the Cancel button text correctly', () => {
      expect(findCancelButton().text()).toBe('Cancel');
    });

    it('renders the Import button text correctly', () => {
      expect(findImportButton().text()).toBe('Import project members');
    });

    it('renders the modal intro text correctly', () => {
      expect(findIntroText()).toBe("You're importing members to the test name project.");
    });

    it('renders the Import button modal without isLoading', () => {
      expect(findImportButton().props('loading')).toBe(false);
    });

    it('sets isLoading to true when the Invite button is clicked', async () => {
      clickImportButton();

      await nextTick();

      expect(findImportButton().props('loading')).toBe(true);
    });
  });

  describe('submitting the import form', () => {
    describe('when the import is successful', () => {
      beforeEach(() => {
        createComponent();

        findProjectSelect().vm.$emit('input', projectToBeImported);

        jest.spyOn(ProjectsApi, 'importProjectMembers').mockResolvedValue();

        clickImportButton();
      });

      it('calls Api importProjectMembers', () => {
        expect(ProjectsApi.importProjectMembers).toHaveBeenCalledWith(
          projectId,
          projectToBeImported.id,
        );
      });

      it('displays the successful toastMessage', () => {
        expect($toast.show).toHaveBeenCalledWith(
          'Successfully imported',
          wrapper.vm.$options.toastOptions,
        );
      });

      it('sets isLoading to false after success', () => {
        expect(findImportButton().props('loading')).toBe(false);
      });
    });

    describe('when the import fails', () => {
      beforeEach(async () => {
        createComponent();

        findProjectSelect().vm.$emit('input', projectToBeImported);

        jest
          .spyOn(ProjectsApi, 'importProjectMembers')
          .mockRejectedValue({ response: { data: { success: false } } });

        clickImportButton();
        await waitForPromises();
      });

      it('displays the generic error message', () => {
        expect(formGroupInvalidFeedback()).toBe('Unable to import project members');
        expect(formGroupErrorState()).toBe(false);
      });

      it('sets isLoading to false after error', () => {
        expect(findImportButton().props('loading')).toBe(false);
      });

      it('clears the error when the modal is closed with an error', async () => {
        expect(formGroupInvalidFeedback()).toBe('Unable to import project members');
        expect(formGroupErrorState()).toBe(false);

        clickCancelButton();

        await nextTick();

        expect(formGroupInvalidFeedback()).toBe('');
        expect(formGroupErrorState()).not.toBe(false);
      });
    });
  });
});
